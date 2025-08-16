import http.server
import ssl
import os

INDEX_FILE = "index.html"

def patch_index_html():
    """Заменяет 'experimentalVK':false на 'experimentalVK':true в index.html."""
    if os.path.exists(INDEX_FILE):
        with open(INDEX_FILE, "r", encoding="utf-8") as f:
            content = f.read()

        new_content = content.replace('"experimentalVK":false', '"experimentalVK":true')

        if new_content != content:
            with open(INDEX_FILE, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"[INFO] {INDEX_FILE} был обновлён (experimentalVK=true)")
        else:
            print(f"[INFO] В {INDEX_FILE} уже установлено experimentalVK=true")
    else:
        print(f"[WARN] Файл {INDEX_FILE} не найден — пропуск замены.")

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Заголовки для SharedArrayBuffer / Threads
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

if __name__ == "__main__":
    # patch_index_html()

    server_address = ("0.0.0.0", 8000)
    httpd = http.server.HTTPServer(server_address, MyHandler)

    httpd.socket = ssl.wrap_socket(
        httpd.socket,
        keyfile="cert/key.pem",
        certfile="cert/cert.pem",
        server_side=True
    )

    print("Serving on https://0.0.0.0:8000")
    httpd.serve_forever()
