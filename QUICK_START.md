# BBK Hardware Bridge - Quick Start Guide

## 🚀 Get Started in 5 Minutes

This guide will help you get the BBK Hardware Bridge up and running quickly.

---

## Step 1: Install Dependencies (2 minutes)

### Install Node.js Packages
```powershell
cd E:\githubNew\bbk\bbk-desktop-app
npm install ws electron-log
```

### Install Python Packages
```powershell
cd python-bridge
pip install fastapi==0.109.0 uvicorn==0.27.0 pyzk==0.9 pyserial==3.5 websockets==12.0
cd ..
```

---

## Step 2: Configure Hardware (1 minute)

Edit `config.json`:

```json
{
  "hardware": {
    "fingerprint": {
      "ip": "192.168.1.201",  ← YOUR DEVICE IP
      "port": 4370
    },
    "doorlock": {
      "port": "COM7"          ← YOUR SERIAL PORT
    }
  }
}
```

---

## Step 3: Test Connection (1 minute)

```powershell
# Test fingerprint device
python -c "from zk import ZK; zk = ZK('192.168.1.201'); conn = zk.connect(); print('✅ Connected!'); conn.disconnect()"

# Test door lock (optional)
python -c "import serial; ser = serial.Serial('COM7', 9600); print('✅ Serial OK'); ser.close()"
```

---

## Step 4: Run Application (1 minute)

```powershell
npm run start:hardware
```

**Expected Output:**
```
BBK Hardware Bridge starting...
Python bridge service started
Connected to fingerprint device
Employee window created on display 0
Member window created on display 1
```

---

## ✅ Verify It's Working

### Test 1: Check Python Bridge
Open browser: http://localhost:8000/health

Should see:
```json
{
  "status": "healthy",
  "fingerprint": { "connected": true },
  "doorlock": { "connected": true }
}
```

### Test 2: Scan Fingerprint
1. Place finger on ZKTeco device
2. Check Electron console for: `Finger scanned: user_id=...`
3. Member screen should show popup

### Test 3: Open Door
1. Click **Hardware** → **Test Door Lock** in menu
2. Door should open for 5 seconds

---

## 🎯 What's Next?

### Add Members to Device
```javascript
// In Employee Dashboard DevTools console
window.hardware.enrollFingerprint(123, 1)
// Scan finger 3 times when prompted
```

### View Real-Time Events
```javascript
// Listen for finger scans
window.hardware.on('finger-scanned', (data) => {
  console.log('Member detected:', data.user_id);
});
```

### Customize Settings
Edit `config.json`:
- Change popup duration: `ui.popup_duration`
- Enable/disable kiosk mode: `screens.member.kiosk_mode`
- Adjust door open time: `hardware.doorlock.open_duration`

---

## 🐛 Quick Troubleshooting

### "Python bridge not connected"
```powershell
# Start manually
cd python-bridge
python main.py
# Check output for errors
```

### "Fingerprint device not found"
- Verify IP in config.json
- Check device is on network: `ping 192.168.1.201`
- Ensure port 4370 is open

### "Door doesn't open"
- Check COM port number in Device Manager
- Update `config.json` with correct port
- Test serial connection manually

---

## 📚 Full Documentation

- **Architecture:** `ARCHITECTURE.md` - System design & data flow
- **Deployment:** `DEPLOYMENT.md` - Production deployment guide
- **API Reference:** `API_REFERENCE.md` - All endpoints & events

---

## 💡 Pro Tips

1. **Use DevTools:** Press `Ctrl+Shift+I` to debug
2. **Check Logs:** `logs/electron.log` and `python-bridge/logs/`
3. **Test Without Hardware:** Python bridge can run in simulation mode
4. **Multiple Screens:** Connect monitor before starting app

---

**You're all set! Enjoy your BBK Hardware Bridge! 🎉**
