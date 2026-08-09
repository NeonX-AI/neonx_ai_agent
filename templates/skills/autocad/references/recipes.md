# AutoCAD AutoLISP — công thức vẽ 2D

Đơn vị: **drawing units** (AutoCAD không có đơn vị cố định). Kiểm tra `(getvar "INSUNITS")` — 4 = mm, 5 = cm, 6 = m. Ví dụ dưới dùng đơn vị người dùng yêu cầu.

## Thực thể cơ bản (dùng `command`)

```lisp
;; Đường thẳng (LINE): các điểm cách nhau bằng dấu cách trong chuỗi, kết thúc bằng ""
(command "_.LINE" "0,0" "100,0" "100,50" "")

;; Đường tròn (CIRCLE): tâm + bán kính
(command "_.CIRCLE" "50,25" 20)

;; Cung tròn (ARC): 3 điểm (đầu - giữa - cuối)
(command "_.ARC" "0,0" "25,10" "50,0")

;; Chữ nhật (RECTANG): 2 điểm chéo
(command "_.RECTANG" "0,0" "100,50")

;; Polyline (PLINE): nhiều điểm, đóng bằng "C" hoặc kết thúc bằng ""
(command "_.PLINE" "0,0" "100,0" "100,50" "0,50" "C")

;; Elip (ELLIPSE): tâm + trục + bán trục
(command "_.ELLIPSE" "50,25" "30,0" 10)

;; Đa giác đều (POLYGON): số cạnh + nội tiếp (I) / ngoại tiếp (C) + tâm + bán kính
(command "_.POLYGON" 6 "50,25" "I" 20)

;; Hatch (HATCH): mẫu + vùng kín (chọn bằng điểm trong)
(command "_.HATCH" "ANSI31" "0,0" "")

;; Text (TEXT / MTEXT)
(command "_.TEXT" "0,-10" 5 0 "HELLO")      ; điểm đặt, chiều cao, góc xoay, nội dung
(command "_.MTEXT" "0,-20" "H" 5 "Ghi chú") ; chiều cao rồi nội dung

;; Dimension (DIMLINEAR): kích thước thẳng giữa 2 điểm
(command "_.DIMLINEAR" "0,0" "100,0" "0,-15")
```

## Vẽ chính xác với `entmake` (không dính UCS/command-line)

```lisp
;; LINE
(entmake (list '(0 . "LINE") '(8 . "0")
               '(10 0.0 0.0 0.0) '(11 100.0 0.0 0.0)))

;; CIRCLE
(entmake (list '(0 . "CIRCLE") '(8 . "0")
               '(10 50.0 25.0 0.0) '(40 . 20.0)))

;; LWPOLYLINE đóng (4 điểm)
(entmake (list '(0 . "LWPOLYLINE") '(8 . "0") '(90 . 4) '(70 . 1)
               '(10 0.0 0.0) '(10 100.0 0.0) '(10 100.0 50.0) '(10 0.0 50.0)))
(entupd (entlast))
```

## Layer, màu, kiểu nét

```lisp
;; Tạo layer mới nếu chưa có
(if (not (tblsearch "LAYER" "TUONG"))
    (command "_.LAYER" "_M" "TUONG" "_C" 1 "TUONG" ""))
;; Đặt layer hiện hành
(command "_.LAYER" "_S" "TUONG" "")
;; Vẽ trên layer cụ thể: thêm (cons 8 "TEN_LAYER") vào entmake
```

## Block — tạo, chèn, nhân bản

```lisp
;; Tạo block từ tập chọn
(command "_.BLOCK" "TEN_BLOCK" "0,0" (ssget) "")
;; Chèn block tại điểm, tỉ lệ 1, xoay 0
(command "_.INSERT" "TEN_BLOCK" "200,0" 1 1 0)
;; Copy đối tượng (chọn bằng cửa sổ rồi dời điểm)
(command "_.COPY" (ssget "C" 0 0 100 50) "" "0,0" "150,0")
;; Array chữ nhật: 3 hàng x 4 cột, cách 50/30
(command "_.ARRAYRECT" (entlast) "" 4 3 1 50 30 0)
```

## Hiệu chỉnh

```lisp
(command "_.OFFSET" 10 (entlast) "0,60" "")        ; offset khoảng cách 10
(command "_.TRIM" "" "ALL" "")                      ; trim tất cả
(command "_.FILLET" "_R" 5 (entlast) (entlast))     ; fillet bán kính 5
(command "_.MOVE" (ssget) "" "0,0" "100,0")         ; di chuyển
(command "_.ROTATE" (ssget) "" "0,0" 45)            ; xoay 45° quanh gốc
(command "_.SCALE" (ssget) "" "0,0" 2)              ; nhân đôi kích thước
(command "_.MIRROR" (ssget) "" "0,0" "100,0" "_N")  ; đối xứng qua trục
```

## Đọc bản vẽ & hiển thị

```lisp
(getvar "INSUNITS")          ; đơn vị bản vẽ (4=mm 5=cm 6=m)
(getvar "EXTMIN") (getvar "EXTMAX")   ; phạm vi bản vẽ
(setq ss (ssget "X"))        ; chọn TẤT CẢ đối tượng
(sslength ss)                ; đếm
(entget (ssname ss 0))       ; đọc thuộc tính đối tượng đầu
(command "_.ZOOM" "_E")      ; zoom toàn bộ bản vẽ (bắt buộc trước screenshot)
(command "_.REGENALL")       ; cập nhật hiển thị
```

## Mẹo

- Kết thúc mọi chuỗi `command` bằng `""` để tránh treo chờ prompt.
- Điểm dạng chuỗi `"x,y"` hoặc list `(list x y 0)` đều được.
- Vẽ xong → `(command "_.REGENALL")` + `(command "_.ZOOM" "_E")` rồi mới screenshot.
- Vẽ nhiều đối tượng lặp lại: test 3 cái trước, rồi mới vòng lặp lớn.
