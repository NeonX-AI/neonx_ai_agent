# Fusion API — công thức 2D/3D

Đơn vị nội bộ: **centimet** (100mm = 10.0), hoặc `adsk.core.ValueInput.createByString("6 mm")`.

## 2D — Sketch

```python
sk = root.sketches.add(root.xYConstructionPlane)   # hoặc xZConstructionPlane, yZConstructionPlane
# hoặc trên mặt body: root.sketches.add(body.faces.item(0))
curves = sk.sketchCurves

# Đường thẳng
curves.sketchLines.addByTwoPoints(adsk.core.Point3D.create(0,0,0), adsk.core.Point3D.create(5,0,0))
# Đường tròn
curves.sketchCircles.addByCenterRadius(adsk.core.Point3D.create(0,0,0), 2.5)
# Cung tròn (tâm - điểm đầu - góc quét radian)
curves.sketchArcs.addByCenterStartSweep(adsk.core.Point3D.create(0,0,0), adsk.core.Point3D.create(0,2,0), math.pi)
# Chữ nhật (2 điểm chéo)
curves.sketchLines.addTwoPointRectangle(adsk.core.Point3D.create(0,0,0), adsk.core.Point3D.create(8,5,0))
# Đa giác đều (nội tiếp, tâm + đỉnh + số cạnh)
curves.sketchLines.addScribedPolygon(adsk.core.Point3D.create(0,0,0), adsk.core.Point3D.create(3,0,0), 6)
# NOTE: SketchPolygons/addWithCenterRadiusSides KHÔNG có ở mọi phiên bản — kiểm tra dir() trước
# Spline qua nhiều điểm
pts = adsk.core.ObjectCollection.create()
pts.add(adsk.core.Point3D.create(0,0,0)); pts.add(adsk.core.Point3D.create(2,1,0)); pts.add(adsk.core.Point3D.create(4,0,0))
curves.sketchFittedSplines.add(pts)
# Điểm
sk.sketchPoints.add(adsk.core.Point3D.create(1,1,0))
# Chữ trên sketch
sk.sketchTexts.add(adsk.core.Point3D.create(0,0,0), 1.0, "ABC")   # point, height, text
```

Constraints & chuyển đổi tọa độ:

```python
sk.geometricConstraints.addCoincident(pt1, pt2)      # trùng
sk.geometricConstraints.addHorizontal(line)          # ngang
sk.geometricConstraints.addSymmetry(p1, p2, axis)    # đối xứng (tên đúng là addSymmetry)
sk.sketchDimensions.addDistanceDimension(pt1, pt2,   # chú ý: sk.sketchDimensions, KHÔNG phải sk.dimensions
    adsk.fusion.DimensionOrientations.HorizontalDimensionOrientation,
    adsk.core.Point3D.create(0,1,0))
sk.modelToSketchSpace(world_point)   # điểm 3D thế giới → tọa độ sketch (bắt buộc khi sketch trên plane riêng)
```

**Profile:** vùng kín tạo bởi curves → `sk.profiles.item(0)` — đầu vào cho extrude/revolve. Sketch hở không có profile.

## 3D — tạo khối

```python
prof = sk.profiles.item(0)

# Extrude (đùn)
ext = root.features.extrudeFeatures.createInput(prof, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
ext.setDistanceExtent(False, adsk.core.ValueInput.createByReal(3.0))   # cm
body = root.features.extrudeFeatures.add(ext).bodies.item(0)

# Revolve (xoay quanh trục)
rev = root.features.revolveFeatures.createInput(prof, axisLine, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
rev.setAngleExtent(False, adsk.core.ValueInput.createByReal(2*math.pi))
root.features.revolveFeatures.add(rev)

# Sweep (quét profile theo đường dẫn)
swp = root.features.sweepFeatures.createInput(toolProfile, path)
root.features.sweepFeatures.add(swp)

# Loft (nối nhiều profile)
loftInput = root.features.loftFeatures.createInput(adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
loftInput.loftSections.add(profile1); loftInput.loftSections.add(profile2)
root.features.loftFeatures.add(loftInput)
```

**FeatureOperations**: `NewBodyFeatureOperation` (khối đầu tiên), `JoinFeatureOperation` (cộng), `CutFeatureOperation` (trừ/cắt), `IntersectFeatureOperation`.

## Chỉnh sửa khối

```python
# Lỗ (Hole feature) — dùng khi lỗ trên mặt PHẲNG
hf = root.features.holeFeatures.createSimpleInput(adsk.core.ValueInput.createByString("6 mm"))
hf.setPositionBySketchPoints(pts_col)          # ObjectCollection chứa sketchPoints, dạng SỐ NHIỀU
hf.setDistanceExtent(adsk.core.ValueInput.createByString("10 mm"))
root.features.holeFeatures.add(hf)

# Bo góc (Fillet)
filletInput = root.features.filletFeatures.createInput()
filletInput.edges.add(edge)
filletInput.setRadius(edge, adsk.core.ValueInput.createByString("2 mm"))
root.features.filletFeatures.add(filletInput)

# Vát mép (Chamfer)
chamferInput = root.features.chamferFeatures.createInput(edge, adsk.core.ValueInput.createByString("1 mm"))
root.features.chamferFeatures.add(chamferInput)

# Vỏ rỗng (Shell)
shellInput = root.features.shellFeatures.createInput()
shellInput.insideThickness = adsk.core.ValueInput.createByReal(0.2)
shellInput.entities.add(face_to_remove)   # mặt mở
root.features.shellFeatures.add(shellInput)

# Gộp/trừ khối (Combine)
comb = root.features.combineFeatures.createInput(targetBody, adsk.core.ObjectCollection.createFromList([toolBody]))
comb.operation = adsk.fusion.FeatureOperations.CutFeatureOperation
root.features.combineFeatures.add(comb)
```

**Pattern:** `rectangularPatternFeatures` (mảng chữ nhật), `circularPatternFeatures` (xoay quanh trục).

## Pattern kiểm chứng: feature phân bố trên mặt cong

```python
import adsk.core, adsk.fusion, math

def fibonacci_sphere(n):   # n điểm đều trên mặt cầu đơn vị
    pts, g = [], (1 + math.sqrt(5)) / 2
    for i in range(n):
        theta = math.acos(1 - 2 * (i + 0.5) / n)
        phi = 2 * math.pi * i / g
        pts.append((math.sin(theta)*math.cos(phi), math.sin(theta)*math.sin(phi), math.cos(theta)))
    return pts

def run(_context: str):
    app = adsk.core.Application.get()
    des = adsk.fusion.Design.cast(app.activeProduct)
    root = des.rootComponent
    R = 5.0  # cm

    # 1) Cầu: revolve nửa hình tròn
    sk = root.sketches.add(root.xYConstructionPlane)
    sk.sketchCurves.sketchArcs.addByCenterStartSweep(
        adsk.core.Point3D.create(0,0,0), adsk.core.Point3D.create(0,R,0), math.pi)
    axis = sk.sketchCurves.sketchLines.addByTwoPoints(
        adsk.core.Point3D.create(0,-R,0), adsk.core.Point3D.create(0,R,0))
    rev = root.features.revolveFeatures.createInput(
        sk.profiles.item(0), axis, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
    rev.setAngleExtent(False, adsk.core.ValueInput.createByReal(2*math.pi))
    sphereBody = root.features.revolveFeatures.add(rev).bodies.item(0)

    # 2) 48 lỗ Ø6mm sâu 2mm
    constructions = root.constructionPlanes; sketches = root.sketches
    extrudes = root.features.extrudeFeatures
    for (ux, uy, uz) in fibonacci_sphere(48):
        origin_pt  = adsk.core.Point3D.create(ux*R, uy*R, uz*R)
        normal_vec = adsk.core.Vector3D.create(ux, uy, uz)     # hướng kính = pháp tuyến mặt cầu
        plane = adsk.core.Plane.create(origin_pt, normal_vec)
        pi = constructions.createInput(); pi.setByPlane(plane)
        cplane = constructions.add(pi)

        sk2 = sketches.add(cplane)
        sk2.sketchCurves.sketchCircles.addByCenterRadius(
            sk2.modelToSketchSpace(origin_pt), 0.3)            # Ø6mm

        ext = extrudes.createInput(sk2.profiles.item(0),
                                   adsk.fusion.FeatureOperations.CutFeatureOperation)
        ext.setDistanceExtent(True, adsk.core.ValueInput.createByReal(0.2))  # sâu 2mm
        ext.participantBodies = [sphereBody]
        try:
            extrudes.add(ext)
        except Exception:
            ext2 = extrudes.createInput(sk2.profiles.item(0),
                                        adsk.fusion.FeatureOperations.CutFeatureOperation)
            ext2.setDistanceExtent(False, adsk.core.ValueInput.createByReal(0.2))
            ext2.participantBodies = [sphereBody]
            extrudes.add(ext2)

        cplane.isLightBulbOn = False   # ẩn mặt phẳng vàng
        sk2.isLightBulbOn = False      # ẩn sketch
    sk.isLightBulbOn = False
    app.activeViewport.fit()
```

Pattern `Plane.create + participantBodies + isLightBulbOn` tổng quát hóa cho mọi bài toán "feature phân bố trên mặt cong" (trụ, xuyến, mặt tự do — tự tính pháp tuyến bề mặt thay vì dựa vào tangent API).
