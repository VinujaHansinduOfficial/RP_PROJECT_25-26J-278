"""
emotion_system.py

Single-file system:
- Train / fine-tune a ResNet18 classifier for 7 emotion classes (IFEED-compatible).
- Run live webcam inference, detect face (MediaPipe), crop, preprocess, get per-frame emotion probs.
- Aggregate per-window (10-30s) statistics and compute LBS and final_score.
- Optionally store face embeddings / probabilities / schema to MongoDB (example).

Usage:
    # Train:
    python emotion_system.py --mode train --data_root /path/to/IFEED_root --epochs 10 --batch_size 32 --save_path model.pt

    # Inference (webcam):
    python emotion_system.py --mode infer --model_path model.pt --window_seconds 15 --cooldown_minutes 10

Notes:
- data_root expected structure: data_root/<class_name>/*.jpg
  where class_name ∈ ['angry','sad','happy','fearful','disgusted','surprised','neutral']
- Requires GPU for reasonably fast training (optional but recommended).
"""

import os
import time
import argparse
import json
from collections import deque, defaultdict
from datetime import datetime, timedelta
import numpy as np
from PIL import Image
from tqdm import tqdm

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as T
import torchvision.models as models

import cv2
import mediapipe as mp
from sklearn.metrics import accuracy_score, classification_report

# Optional Mongo
try:
    from pymongo import MongoClient
    MONGODB_AVAILABLE = True
except Exception:
    MONGODB_AVAILABLE = False

# -----------------------
# Config / constants
# -----------------------
EMOTION_CLASSES = ['angry','sad','happy','fearful','disgusted','surprised','neutral']
NUM_CLASSES = len(EMOTION_CLASSES)
IMG_SIZE = 224

# -----------------------
# Dataset
# -----------------------
class ImageFolderDataset(Dataset):
    def __init__(self, root, classes=EMOTION_CLASSES, transform=None):
        self.root = root
        self.transform = transform
        self.samples = []
        self.class_to_idx = {c:i for i,c in enumerate(classes)}
        for c in classes:
            d = os.path.join(root, c)
            if not os.path.isdir(d):
                continue
            for fname in os.listdir(d):
                if fname.lower().endswith(('.jpg','.jpeg','.png')):
                    self.samples.append((os.path.join(d,fname), self.class_to_idx[c]))
        if len(self.samples)==0:
            raise RuntimeError(f"No images found in {root}. Expect structure root/class/*.jpg")
    def __len__(self):
        return len(self.samples)
    def __getitem__(self, idx):
        p,label = self.samples[idx]
        img = Image.open(p).convert('RGB')
        if self.transform:
            img = self.transform(img)
        return img, label

# -----------------------
# Model
# -----------------------
def build_model(num_classes=NUM_CLASSES, pretrained=True, device='cpu'):
    model = models.resnet18(pretrained=pretrained)
    in_features = model.fc.in_features
    model.fc = nn.Linear(in_features, num_classes)
    model = model.to(device)
    return model

# -----------------------
# Train / Evaluate
# -----------------------
def train_loop(args):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print("Using device:", device)

    transform_train = T.Compose([
        T.Resize((IMG_SIZE, IMG_SIZE)),
        T.RandomHorizontalFlip(),
        T.ColorJitter(brightness=0.2, contrast=0.2),
        T.RandomRotation(6),
        T.ToTensor(),
        T.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
    ])
    transform_val = T.Compose([
        T.Resize((IMG_SIZE, IMG_SIZE)),
        T.ToTensor(),
        T.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
    ])

    # Split dataset (80/20)
    ds = ImageFolderDataset(args.data_root, transform=transform_train)
    n = len(ds)
    idxs = list(range(n))
    np.random.shuffle(idxs)
    split = int(0.8*n)
    train_idx, val_idx = idxs[:split], idxs[split:]

    train_samples = [ds.samples[i] for i in train_idx]
    val_samples = [ds.samples[i] for i in val_idx]

    class TempDS(Dataset):
        def __init__(self, samples, transform):
            self.samples = samples
            self.transform = transform
        def __len__(self): return len(self.samples)
        def __getitem__(self, idx):
            p,label = self.samples[idx]
            img = Image.open(p).convert('RGB')
            if self.transform:
                img = self.transform(img)
            return img, label

    train_ds = TempDS(train_samples, transform_train)
    val_ds = TempDS(val_samples, transform_val)

    train_loader = DataLoader(train_ds, batch_size=args.batch_size, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False, num_workers=4)

    model = build_model(pretrained=True, device=device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=args.lr, weight_decay=1e-5)
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.5)

    best_val_acc = 0.0
    for epoch in range(args.epochs):
        model.train()
        running_loss = 0.0
        all_preds = []
        all_labels = []
        for imgs, labels in tqdm(train_loader, desc=f"Epoch {epoch+1}/{args.epochs} [train]"):
            imgs = imgs.to(device)
            labels = labels.to(device)
            optimizer.zero_grad()
            outputs = model(imgs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item() * imgs.size(0)
            preds = outputs.argmax(dim=1).detach().cpu().numpy()
            all_preds.extend(preds.tolist())
            all_labels.extend(labels.detach().cpu().numpy().tolist())
        scheduler.step()
        train_loss = running_loss / len(train_loader.dataset)
        train_acc = accuracy_score(all_labels, all_preds)

        # Validation
        model.eval()
        all_preds = []
        all_labels = []
        with torch.no_grad():
            for imgs, labels in tqdm(val_loader, desc=f"Epoch {epoch+1}/{args.epochs} [val]"):
                imgs = imgs.to(device)
                labels = labels.to(device)
                outputs = model(imgs)
                preds = outputs.argmax(dim=1).detach().cpu().numpy()
                all_preds.extend(preds.tolist())
                all_labels.extend(labels.detach().cpu().numpy().tolist())
        val_acc = accuracy_score(all_labels, all_preds)
        print(f"Epoch {epoch+1} - train_loss: {train_loss:.4f} train_acc: {train_acc:.4f} val_acc: {val_acc:.4f}")
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save({'model_state': model.state_dict(), 'classes': EMOTION_CLASSES}, args.save_path)
            print("Saved best model to", args.save_path)

    print("Training finished. Best val acc:", best_val_acc)

# -----------------------
# Utilities: preprocess crop
# -----------------------
mp_face = mp.solutions.face_detection.FaceDetection(model_selection=0, min_detection_confidence=0.5)

def detect_face_and_crop(frame, pad=0.2):
    # frame: BGR from cv2
    h,w = frame.shape[:2]
    img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = mp_face.process(img_rgb)
    if not results.detections:
        return None
    # choose first detection
    d = results.detections[0]
    bbox = d.location_data.relative_bounding_box
    x = int(bbox.xmin * w)
    y = int(bbox.ymin * h)
    bw = int(bbox.width * w)
    bh = int(bbox.height * h)
    # add padding
    px = int(bw * pad)
    py = int(bh * pad)
    x1 = max(0, x - px)
    y1 = max(0, y - py)
    x2 = min(w, x + bw + px)
    y2 = min(h, y + bh + py)
    crop = frame[y1:y2, x1:x2]
    if crop.size == 0:
        return None
    return crop

def preprocess_crop_for_model(crop):
    img = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    img = Image.fromarray(img)
    transform = T.Compose([
        T.ToTensor(),
        T.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]),
    ])
    return transform(img).unsqueeze(0)  # 1xC x H x W

# -----------------------
# Inference + Window aggregation + scoring
# -----------------------
def load_model_for_infer(path, device):
    checkpoint = torch.load(path, map_location=device)
    model = build_model(pretrained=False, device=device)
    model.load_state_dict(checkpoint['model_state'])
    model.eval()
    return model

def softmax(x):
    e = np.exp(x - np.max(x))
    return e / e.sum()

def run_webcam_inference(args):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = load_model_for_infer(args.model_path, device)
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise RuntimeError("Cannot open webcam (index 0).")
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    frames_per_window = int(args.window_seconds * fps)
    print(f"FPS detected ~ {fps:.1f}, using frames_per_window = {frames_per_window}")

    # State for cooldown
    last_intervention_time = datetime.min

    # buffer for frame probs
    probs_buffer = deque(maxlen=frames_per_window)
    ts_buffer = deque(maxlen=frames_per_window)

    # Optional mongodb
    mongo_client = None
    if args.mongo_uri and MONGODB_AVAILABLE:
        mongo_client = MongoClient(args.mongo_uri)
        db = mongo_client.get_database(args.mongo_db or "emotion_db")
        col = db.get_collection(args.mongo_collection or "sessions")
        print("MongoDB enabled - will insert session documents")
    else:
        col = None

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            crop = detect_face_and_crop(frame)
            if crop is None:
                # no face detected -> push a neutral prob
                neutral_prob = np.zeros(NUM_CLASSES); neutral_prob[EMOTION_CLASSES.index('neutral')] = 1.0
                probs_buffer.append(neutral_prob)
                ts_buffer.append(datetime.utcnow().isoformat())
            else:
                inp = preprocess_crop_for_model(crop).to(device)
                with torch.no_grad():
                    out = model(inp)  # logits
                    logits = out.cpu().numpy().squeeze()
                    p = softmax(logits)
                    probs_buffer.append(p)
                    ts_buffer.append(datetime.utcnow().isoformat())
            # Show minimal UI
            avg_probs = np.mean(np.stack(probs_buffer), axis=0) if len(probs_buffer)>0 else np.zeros(NUM_CLASSES)
            label_idx = int(np.argmax(avg_probs))
            label = EMOTION_CLASSES[label_idx]
            prob_val = avg_probs[label_idx]
            cv2.putText(frame, f"{label} {prob_val:.2f}", (10,30), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,255,0), 2)
            cv2.imshow("Emotion Live", frame)
            # when buffer full -> aggregate and compute score
            if len(probs_buffer) >= frames_per_window:
                # window features
                arr = np.stack(probs_buffer)  # N x C
                mean = arr.mean(axis=0)
                mx = arr.max(axis=0)
                std = arr.std(axis=0)
                # facial_distress heuristic: combine negative emotions (angry, sad, fearful, disgusted) weighted
                distress_idx = [EMOTION_CLASSES.index(c) for c in ['angry','sad','fearful','disgusted']]
                facial_distress = float(mean[distress_idx].sum() / len(distress_idx))  # 0..1 approx

                # optional HR_change and inactivity - no HR here, so simulate 0
                HR_change = 0.0
                inactivity = 0.0

                LBS = 0.5*facial_distress + 0.3*HR_change + 0.2*inactivity
                # QS and CFS placeholders (could be pulled from DB or UI)
                QS = 0.0  # set if user filled survey recently (scale 0..10); we'll normalize shortly
                QS_norm = QS/10.0
                CFS_recent = 1.0  # assume clinician_rating (1-10) -> normalized: if 10 then 1.0; (we use (1 - CFS_recent) in formula)
                final_score = args.w_b*LBS + args.w_q*QS_norm + args.w_c*(1 - CFS_recent)

                # clamp
                final_score = float(np.clip(final_score, 0.0, 1.0))
                print(f"Window aggregated | facial_distress={facial_distress:.3f} LBS={LBS:.3f} final_score={final_score:.3f}")

                # Decide intervention
                now = datetime.utcnow()
                if final_score >= args.high_threshold:
                    if now - last_intervention_time > timedelta(minutes=args.cooldown_minutes):
                        print("[ACTION] Immediate calming intervention (guided breathing). Cooldown started.")
                        last_intervention_time = now
                        intervention = "guided_breathing"
                    else:
                        print("[INFO] In cooldown - no new intervention.")
                        intervention = "cooldown"
                elif final_score >= args.mid_threshold:
                    print("[ACTION] Micro-intervention suggested.")
                    intervention = "micro_intervention"
                else:
                    intervention = "none"

                # Prepare doc to store
                doc = {
                    "session_id": args.session_id or f"session_{int(time.time())}",
                    "window_start": ts_buffer[0] if len(ts_buffer)>0 else datetime.utcnow().isoformat(),
                    "facial_probs_mean": mean.tolist(),
                    "facial_probs_max": mx.tolist(),
                    "facial_probs_std": std.tolist(),
                    "LBS": float(LBS),
                    "QS": float(QS_norm),
                    "CFS_recent": float(CFS_recent),
                    "final_score": float(final_score),
                    "intervention": intervention,
                    "timestamp": datetime.utcnow().isoformat()
                }
                if col is not None:
                    col.insert_one(doc)
                # clear buffer (start fresh)
                probs_buffer.clear()
                ts_buffer.clear()
            # key controls
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
    finally:
        cap.release()
        cv2.destroyAllWindows()
        if mongo_client:
            mongo_client.close()

# -----------------------
# CLI
# -----------------------
def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--mode', choices=['train','infer'], required=True)
    # training args
    p.add_argument('--data_root', type=str, default=None)
    p.add_argument('--epochs', type=int, default=8)
    p.add_argument('--batch_size', type=int, default=32)
    p.add_argument('--lr', type=float, default=3e-4)
    p.add_argument('--save_path', type=str, default='emotion_model.pt')
    # infer args
    p.add_argument('--model_path', type=str, default='emotion_model.pt')
    p.add_argument('--window_seconds', type=float, default=15.0)
    p.add_argument('--mid_threshold', type=float, default=0.50)
    p.add_argument('--high_threshold', type=float, default=0.75)
    p.add_argument('--cooldown_minutes', type=int, default=10)
    p.add_argument('--session_id', type=str, default=None)
    # weights for fusion
    p.add_argument('--w_b', type=float, default=0.5)
    p.add_argument('--w_q', type=float, default=0.25)
    p.add_argument('--w_c', type=float, default=0.25)
    # mongodb
    p.add_argument('--mongo_uri', type=str, default=None)
    p.add_argument('--mongo_db', type=str, default=None)
    p.add_argument('--mongo_collection', type=str, default=None)
    return p.parse_args()

if __name__ == '__main__':
    args = parse_args()
    if args.mode == 'train':
        if not args.data_root:
            raise RuntimeError("Training requires --data_root pointing to dataset root")
        train_loop(args)
    elif args.mode == 'infer':
        if not os.path.exists(args.model_path):
            raise RuntimeError("Model path not found. Provide --model_path")
        run_webcam_inference(args)
