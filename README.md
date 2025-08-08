## my-script

Installer interaktif untuk menjalankan kumpulan skrip di folder `script/`. Bisa dijalankan langsung via curl (one-liner) atau secara lokal. Saat dijalankan via curl, installer akan otomatis clone/pull repo ini sebelum menampilkan menu pilihan skrip.

Repo: [localan/my-script](https://github.com/localan/my-script)

### Prasyarat
- bash
- git
- curl

### Cara Cepat (one‑liner)
Jalankan perintah berikut:

```bash
bash <(curl -L link.dwx.my.id/my-script)
```

Opsi kustom lokasi repo dan URL repo (opsional):

```bash
MY_SCRIPT_DIR="$HOME/my-script" \
MY_SCRIPT_REPO_URL="https://github.com/localan/my-script" \
bash <(curl -L link.dwx.my.id/my-script)
```

### Cara Lokal
1) Clone repo (jika belum):
```bash
git clone https://github.com/localan/my-script "$HOME/my-script"
```
2) Jalankan installer:
```bash
cd "$HOME/my-script"
./install.sh
```

### Cara Kerja
- Jika dijalankan via curl, skrip akan:
  - Clone ke `MY_SCRIPT_DIR` (default: `$HOME/my-script`) bila belum ada, atau `git pull` bila sudah ada.
  - Menjalankan `install.sh` lokal dengan mode interaktif.
- Installer menampilkan daftar skrip `.sh` di `script/` dan mendukung:
  - Memilih beberapa nomor sekaligus (mis. `1 3 5`)
  - Memilih semua (`a`)
  - Keluar (`q`)
  - Konfirmasi sebelum eksekusi dan opsi lanjut/berhenti jika ada error per skrip

### Variabel Lingkungan
- `MY_SCRIPT_REPO_URL`: URL git repo (default: `https://github.com/localan/my-script`).
- `MY_SCRIPT_DIR`: Lokasi direktori repo lokal (default: `$HOME/my-script`).

Contoh:
```bash
MY_SCRIPT_DIR="/opt/my-script" bash <(curl -L link.dwx.my.id/my-script)
```

### Troubleshooting
- "command not found: git" → install `git` terlebih dahulu.
- "command not found: curl" → install `curl` terlebih dahulu.
- "Permission denied" saat menjalankan lokal → pastikan executable:
  ```bash
  chmod +x ./install.sh
  ```
- Koneksi lambat/gagal → coba ulang beberapa saat kemudian atau periksa koneksi/Firewall/Proxy.

### Lisensi
Gunakan sesuai kebutuhan Anda. Jika ingin menambah skrip, letakkan file `.sh` baru di folder `script/`.

### Microsoft Activation
```bash
irm https://link.dwx.my.id/mas | iex
```