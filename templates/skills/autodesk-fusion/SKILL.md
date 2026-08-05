---
name: "autodesk-fusion"
description: "Draw 2D/3D in Autodesk Fusion 360 via MCP: run Python API scripts. Covers sketches, extrude, revolve, holes, fillets, patterns, viewport screenshots."
---

# Autodesk Fusion — vẽ 2D/3D qua MCP

Dùng skill này khi user yêu cầu **vẽ, tạo, sửa, đọc mô hình 2D/3D trong Autodesk Fusion 360**, hoặc **chụp ảnh màn hình viewport Fusion**. Agent điều khiển Fusion bằng cách chạy script Python (Fusion API) trong Fusion qua MCP server. Client code: copy `scripts/fusion_mcp.py` vào nơi làm việc rồi `import fusion_mcp as fm`. Công thức 2D/3D đầy đủ: `references/recipes.md`.

## 0. QUY TẮC ĐẦU RA — BẮT BUỘC

**Mọi tác vụ vẽ/sửa/tạo model sau khi hoàn thành: LUÔN chụp ảnh viewport (mục 2b) và gửi kèm ảnh cho user trong reply.** Không báo "xong" bằng chữ suông — user muốn nhìn thấy kết quả. Gọi `app.activeViewport.fit()` trong script ngay trước khi chụp để model lọt khung hình; cần góc khác thì xoay/chụp thêm ảnh.

## 1. Điều kiện cần

- Fusion 360 đang mở trên máy user, MCP server add-in chạy (mặc định `http://localhost:27182`, Streamable HTTP). Từ container → `host.docker.internal`.
- Chưa chạy: nhờ user bật add-in (Utilities → Add-ins), kiểm tra bằng script đọc nhanh trước khi kết luận treo.

## 2. Kết nối MCP (trình tự sai là lỗi)

- `POST {BASE}/mcp`, headers: `Host: 127.0.0.1:27182`, `Content-Type: application/json`, `Accept: application/json, text/event-stream`
- Handshake: `initialize` (protocolVersion `2025-03-26`) → lấy `Mcp-Session-Id` từ response headers → gửi `notifications/initialized` (KHÔNG có trường `id`) → mọi request sau kèm header session.
- Tools: `fusion_mcp_execute` (chạy script), `fusion_mcp_read` (đọc model + **screenshot**), `fusion_mcp_update` (undo/redo).
- Dùng client ở `scripts/fusion_mcp.py` (chỉ stdlib `urllib` — container KHÔNG có requests/pip).

## 2b. Screenshot viewport — CÁCH NHANH NHẤT (đã kiểm chứng)

```python
import fusion_mcp as fm
fm.initialize()
fm.screenshot("fusion_viewport.png")   # chụp qua fusion_mcp_read queryType=screenshot → PNG
```

Gửi PNG qua `message` tool attachment. `queryType: "screenshot"`, tùy chọn `antiAliasing` (default true). **KHÔNG** dùng `saveAsImageFile()` + print base64 qua stdout — pitfall 8.

## 3. Quy tắc script Fusion

- Entry point BẮT BUỘC: `def run(_context: str):`
- Đơn vị nội bộ: **centimet** (100mm = 10.0), hoặc `ValueInput.createByString("6 mm")`
- Boilerplate: `app = adsk.core.Application.get()`; `des = adsk.fusion.Design.cast(app.activeProduct)` (KHÔNG phải `adsk.fusion.FusionDesign`); `root = des.rootComponent`
- Lỗi trả trong `result.content[0].text` với `"success": false` → đọc để debug, đừng đoán
- Cuối script: `app.activeViewport.fit()` + print tóm tắt NGẮN (pitfall 8)

## 4. Pitfalls — đã trả giá, đừng lặp lại

1. **"No target body found to cut or intersect!"** — normal plane bị lật. KHÔNG dùng `setByTangentAtPoint()` trên mặt cong; dùng `adsk.core.Plane.create(origin_pt, normal_vec)` + `setByPlane(plane)` + set `participantBodies = [targetBody]` rõ ràng. Fallback: `setDistanceExtent(True,...)` rồi `(False,...)`.
2. **`setByNormalAtPoint` KHÔNG tồn tại.** Cần plane theo pháp tuyến tự chọn → `setByPlane(adsk.core.Plane.create(point, normal))`.
3. **Ẩn plane/sketch phụ:** `ConstructionPlane.isVisible` là READ-ONLY → AttributeError. Dùng `obj.isLightBulbOn = False` (được cho cả plane lẫn sketch). KHÔNG xóa plane/sketch mà feature tham chiếu — chỉ ẩn, ẩn ngay trong vòng lặp.
4. **Fusion quá tải:** vài trăm planes/sketches khiến MỌI script timeout. Check `root.bRepBodies.count`, `root.sketches.count`, `root.constructionPlanes.count` trước; quá bẩn → nhờ user tạo design mới.
5. **Timeout & test:** timeout client ≥ thời gian ước tính (việc nặng → 600s). LUÔN test 3–5 đối tượng trước batch lớn. Script đọc nhanh xác nhận server sống trước khi nghi treo.
6. **Tham chiếu hết hạn:** sau mỗi feature cut, `body`/`face` cũ có thể stale — lấy lại `root.bRepBodies.item(0)` trong vòng lặp nếu lỗi lạ.
7. **Tên API khác giữa các phiên bản:** đã gặp `addSymmetric` (đúng: `addSymmetry`), `sk.dimensions` (đúng: `sk.sketchDimensions`), `SketchPolygons` (không tồn tại). Trước khi dùng API mới, kiểm tra bằng script `dir(obj)`.
8. **stdout của `fusion_mcp_execute` bị TRUNCATE với dữ liệu lớn** (~vài trăm KB): `print(base64 ảnh)` mất sạch dữ liệu, response thành `{"message": "", "success": true}` → b64decode lỗi padding. Muốn ảnh viewport: dùng `fm.screenshot()` (mục 2b), đừng đi vòng qua script.

## 5. Checklist trước khi chạy

- [ ] Design hiện tại sạch? (check bRepBodies/sketches/planes counts)
- [ ] Timeout client đủ lớn (600s cho việc nặng)
- [ ] Test nhỏ (3 đối tượng) trước batch lớn
- [ ] Fallback hướng cắt (True/False)
- [ ] Ẩn đối tượng phụ (`isLightBulbOn = False`) trong vòng lặp
- [ ] **Xong việc → chụp screenshot + gửi ảnh cho user**
