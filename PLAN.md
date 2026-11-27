# Kế Hoạch Phát Triển Game: Mad Kitchen (Little Kitchen Theft)

* **Nền tảng / Engine:** Godot 4.x (GDScript — bản Standard, không cần .NET/C#)
* **Thể loại:** Stealth / Explore / Puzzle — Góc nhìn thứ 3 (3D Environment + 2D Billboard Characters)
* **Tham chiếu concept:** `game-concept.vi (1).md`
* **Mục tiêu MVP:** 1 căn bếp hoàn chỉnh (tỷ lệ khổng lồ), nhân vật chuột 2D billboard (di chuyển, chui khe, kéo lùi đồ nặng), 1 AI Lão đầu bếp theo thời gian biểu cố định, hệ thống Mouse Sense, tối thiểu 2 lối thoát (Bad Ending & Good Ending) và 3–5 manh mối.

---

## Phần 1: Phân Công Công Việc — AI Làm Gì & Bạn Cần Hỗ Trợ Gì?

Vì bạn chưa biết code Godot, mình (AI) sẽ đảm nhận toàn bộ phần **lập trình GDScript, cấu trúc thư mục, shader và logic hệ thống**. Tuy nhiên, có những khâu mang tính trực quan hoặc cần thao tác trên giao diện Godot Editor mà AI không thể tự làm thay hoàn toàn:

| Khâu công việc | AI (Mình) làm được | Bạn cần hỗ trợ |
| :--- | :--- | :--- |
| **Lập trình GDScript** | Viết 100% script: di chuyển chuột, camera, kéo đồ, AI đầu bếp, Mouse Sense, UI, hệ thống Ending. | Không cần viết code; chỉ cần copy/pull code về mở trong Godot. |
| **Cấu trúc Project & Scene** | Tạo sẵn cây thư mục, file `.tscn` cơ bản, `project.godot`, Input Map, Autoloads, Shader (làm mờ vật cản). | Mở project trong Godot Editor (mình sẽ hướng dẫn từng bước). |
| **Chạy thử & Cảm nhận (Playtest)** | Đọc log lỗi từ console nếu game crash. | **Bắt buộc:** Bấm F5 chạy game trên máy bạn, đi thử, chui gầm tủ, chụp ảnh/quay clip hoặc mô tả cảm giác ("camera bị giật", "chuột nhảy hụt") để mình chỉnh thông số. |
| **Dựng Level 3D (Bếp) & NavMesh** | Dựng phòng greybox (khối hộp đơn giản) bằng code/scene mẫu để test. | Sắp xếp bàn ghế, tủ lạnh, khe hở trong không gian 3D của Godot cho hợp mắt và bấm nút **Bake NavigationMesh** trong Editor (mình sẽ chỉ đúng nút cần bấm). |
| **Art 2D (Chuột, Đầu bếp, Đồ ăn, UI)** | Code hệ thống tự đổi sprite theo 4–8 hướng và hiệu ứng đổ bóng. | Vẽ hoặc nhờ team 2D/AI tạo sprite sheet (PNG nền trong suốt) cho chuột, đầu bếp, icon đồ ăn, giấy note. *(Lúc mới code sẽ dùng hình tạm/placeholder).* |
| **Model 3D & Âm thanh** | Gắn âm thanh 3D và hiệu ứng vào code. | Tìm/tải model bếp low-poly (`.glb`/`.gltf` từ Kenney, Poly Pizza, Sketchfab) và file âm thanh (`.wav`/`.ogg`). |
| **Cài đặt Godot & Export** | Hướng dẫn cấu hình Export. | Tải và cài **Godot 4.x (Standard)** trên Windows, tạo tài khoản/cấu hình nếu cần export `.exe`. |

---

## Phần 2: Kiến Trúc Project Godot 4 Đề Xuất

### 2.1. Cấu trúc thư mục

```text
res://
├── assets/
│   ├── sprites/          # Sprite 2D billboard (chuột, đầu bếp, đồ ăn)
│   ├── models/           # Model 3D môi trường bếp (.glb)
│   ├── audio/            # SFX (bước chân, tim đập, gặm, kéo đồ) & BGM
│   └── ui/               # Font, khung thoại, giấy note, icon
├── scenes/
│   ├── main/             # Main.tscn (scene gốc điều phối run)
│   ├── levels/           # Kitchen_Greybox.tscn -> Kitchen_Main.tscn
│   ├── player/           # MousePlayer.tscn (CharacterBody3D + Camera + Sprite3D)
│   ├── ai/               # ChefAI.tscn (CharacterBody3D + NavAgent + Vision/Hearing)
│   ├── props/            # Đồ ăn nhỏ/lớn, dây gặm được, đồ đẩy được, giấy note, lối thoát
│   └── ui/               # HUD (Mouse Sense, túi đồ, prompt tương tác), NoteViewer, EndingScreen
├── scripts/
│   ├── autoload/         # GameManager.gd, SoundEventBus.gd, TimeManager.gd
│   ├── player/           # MouseController.gd, CameraRig.gd, Billboard4Dir.gd
│   ├── ai/               # ChefStateMachine.gd, ChefSchedule.gd (Resource)
│   ├── interactables/    # Interactable.gd, FoodItem.gd, DragableItem.gd, Chewable.gd, NoteItem.gd
│   └── ui/               # MouseSenseUI.gd, DialogueUI.gd
├── shaders/
│   └── wall_dither.gdshader   # Làm mờ vật cản chắn giữa Camera và Chuột
└── resources/
    └── schedules/        # Dữ liệu thời gian biểu của Lão đầu bếp (.tres)
```

### 2.2. Hệ thống Autoload (Singleton toàn cục)
1. **`GameManager.gd`**: Quản lý trạng thái run (`PLAYING`, `PAUSED`, `CAUGHT`, `ESCAPED`), số lượng đồ ăn đã gom, kiểm tra điều kiện Bad/Good Ending, reset run nhanh.
2. **`SoundEventBus.gd`**: Hệ thống Signal trung tâm. Khi chuột chạy nhanh, kéo đồ ăn nặng hoặc làm rơi đồ, phát tín hiệu `sound_emitted(position: Vector3, radius: float, loudness: float)` -> Chef AI lắng nghe để chuyển sang trạng thái điều tra.
3. **`TimeManager.gd`**: Đồng hồ nội bộ của căn bếp (ví dụ 1 vòng lặp = 3–5 phút thực tế), giúp Chef AI đi đúng lịch trình (Timetable) và người chơi có thể học thuộc quy luật.

### 2.3. Quy ước Physics Layers (Rất quan trọng để không bug)
* **Layer 1 (`World`)**: Sàn, tường, bàn bếp, tủ lạnh.
* **Layer 2 (`Player`)**: Nhân vật chuột.
* **Layer 3 (`Enemy`)**: Lão đầu bếp.
* **Layer 4 (`Interactable`)**: Đồ ăn, giấy note, dây cần gặm, công tắc.
* **Layer 5 (`HideZone` / `LowGap`)**: Vùng gầm tủ, khe hẹp (chuột đi lọt khi cúi/chui, đầu bếp không vào được).
* **Layer 6 (`CameraIgnore`)**: Vật thể nhỏ không làm camera bị giật lùi.

---

## Phần 3: Lộ Trình Triển Khai Chi Tiết (Từng Giai Đoạn)

### Giai đoạn 0: Khởi tạo & Môi trường (Ngày 1–2)
- [ ] Cài đặt **Godot 4.x (Standard)** trên máy bạn.
- [ ] Tạo project Godot mới ngay trong thư mục repo GitHub này (`project.godot`).
- [ ] Thiết lập `.gitignore` chuẩn cho Godot 4 (bỏ qua `.godot/`, `*.tmp`, bản build).
- [ ] Cấu hình **Input Map** (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `crouch`, `sprint`, `interact`, `drag`).
- [ ] Tạo cấu trúc thư mục và 3 Autoloads (`GameManager`, `SoundEventBus`, `TimeManager`).

---

### Giai đoạn 1: Prototype Camera 3D, Di Chuyển Chuột & 2D Billboard (Tuần 1–2)
> **Mục tiêu:** Giải quyết rủi ro kỹ thuật lớn nhất trước khi làm tính năng khác — điều khiển chuột mượt mà trong không gian tỷ lệ khổng lồ và không bị kẹt camera khi chui gầm tủ.

1. **Dựng phòng Greybox (`Kitchen_Greybox.tscn`):**
   - Quy ước tỷ lệ: Chuột cao ~`0.2m`, Lão đầu bếp cao ~`2.0m`, Bàn bếp cao ~`1.0m`, Gầm tủ hở ~`0.3m`.
   - Đặt vài khối hộp đại diện: Sàn, 4 bức tường, 1 bàn bếp, 1 tủ lạnh, 1 khe gầm tủ để test chui.
2. **Nhân vật Chuột (`MousePlayer.tscn`):**
   - Node gốc: `CharacterBody3D`.
   - Di chuyển 3D theo hướng Camera: Đi bộ, Chạy nhanh (gây ồn), Nhảy (`jump_velocity` + gravity), Cúi/Chui (`crouch` thu nhỏ `CollisionShape3D` và kiểm tra trần bằng `ShapeCast3D` để không đứng dậy khi đang ở gầm tủ).
3. **Hệ thống Camera Góc Nhìn Thứ 3 (`CameraRig.gd`):**
   - Cấu trúc: `Node3D (Pivot)` -> `SpringArm3D` -> `Camera3D`.
   - Xoay chuột mượt, giới hạn góc ngẩng/cúi.
   - **Xử lý chống che tầm nhìn (Occlusion):** Bắn `RayCast3D` từ Camera tới Chuột; nếu trúng tường/tủ, tự động bật hiệu ứng làm mờ (`wall_dither.gdshader` hoặc giảm alpha) để luôn thấy chuột khi ở sau bàn/gầm tủ.
4. **Nhân vật 2D Billboard (`Billboard4Dir.gd`):**
   - Dùng `Sprite3D` (chế độ `Billboard = Y-Billboard`).
   - Tính góc giữa hướng nhìn Camera và hướng di chuyển của Chuột (`atan2`) để tự đổi frame/hướng sprite (4 hướng: Trước, Sau, Trái, Phải — có thể nâng lên 8 hướng sau).
   - **Blob Shadow (Bóng tròn dưới chân):** Đặt 1 `Decal` hoặc `MeshInstance3D` hình tròn đen mờ chiếu thẳng xuống sàn dưới chân chuột -> bắt buộc phải có để người chơi căn khoảng cách khi nhảy lên kệ/bàn bếp.

**Tiêu chí hoàn thành Giai đoạn 1:** Chuột chạy, nhảy lên bục, chui qua gầm tủ `0.3m` mượt mà; camera không bị kẹt hoặc che khuất; xoay camera quanh chuột thấy sprite đổi hướng đúng.

---

### Giai đoạn 2: Tương Tác Môi Trường, Đồ Ăn & Cơ Chế Kéo Lùi (Tuần 2–3)
> **Mục tiêu:** Hiện thực hóa **Pillar 2 (Greed vs. Survival)** — càng tham, càng nặng, càng dễ chết.

1. **Hệ thống Tương tác chung (`Interactable.gd`):**
   - Chuột có 1 `Area3D` / `RayCast3D` phía trước. Khi lại gần vật thể tương tác, hiện prompt UI nhỏ (`[E] Ăn`, `[E] Kéo`, `[Giữ E] Gặm dây`).
2. **Đồ ăn nhỏ (Small Food):**
   - Tương tác để nhặt vào túi (hoặc ăn ngay).
   - Mỗi món trong túi tăng **Trọng lượng (Weight)** -> giảm nhẹ tốc độ chạy, tăng bán kính tiếng ồn khi chạy.
3. **Đồ ăn lớn — Cơ chế Kéo Lùi (Heavy Food Dragging):**
   - Khi nhấn giữ/bấm tương tác vào miếng phô mai/đùi gà lớn:
     - Chuột chuyển sang trạng thái `DRAGGING`: quay lưng lại phía hướng kéo (hoặc nối với vật qua khoảng cách cố định).
     - Tốc độ di chuyển giảm mạnh (40–50%), **không thể nhảy hoặc chạy nhanh**.
     - Gây tiếng ồn liên tục (`SoundEventBus` phát sóng âm mỗi 0.5s).
     - Cho phép buông đồ ăn ra ngay lập tức (`[E]` hoặc chuột phải) để bỏ chạy khi thấy nguy hiểm.
4. **Tương tác giải đố cơ bản:**
   - **Đẩy đồ nhẹ (`PushableBox`):** Dùng `RigidBody3D` hoặc đẩy theo lưới để chuột kê làm bục nhảy lên cao.
   - **Gặm vật cản (`Chewable`):** Giữ phím `[E]` trong vài giây (có thanh tiến trình + phát tiếng gặm nhỏ) để đứt dây/mở nắp ống thông gió.

**Tiêu chí hoàn thành Giai đoạn 2:** Chuột nhặt được đồ nhỏ, kéo lùi được đồ lớn, buông đồ chạy trốn được, đẩy được hộp để nhảy lên bàn cao.

---

### Giai đoạn 3: AI Lão Đầu Bếp & Hệ Thống Mouse Sense (Tuần 3–5)
> **Mục tiêu:** Hiện thực hóa **Pillar 1 (Knowledge is Progression)** & **Pillar 3 (Readable Threat)**.

1. **Navigation & Chef Rig (`ChefAI.tscn`):**
   - Thiết lập `NavigationRegion3D` cho sàn bếp.
   - Chef dùng `CharacterBody3D` + `NavigationAgent3D` + `Sprite3D` (billboard 4/8 hướng, kích thước khổng lồ).
2. **Thời gian biểu cố định (`ChefSchedule.gd`):**
   - Danh sách các điểm tuần tra (`Marker3D`) gắn với hành động và thời gian dừng (ví dụ: *00:00 Bếp ga (15s) -> 00:15 Bồn rửa (10s) -> 00:25 Tủ lạnh (10s) -> 00:35 Bàn chặt (15s)*).
3. **State Machine của Đầu bếp (`ChefStateMachine.gd`):**
   - `PATROL_TIMETABLE`: Đi theo đúng lịch trình cố định, tới điểm dừng thì quay mặt làm việc.
   - `INVESTIGATE`: Khi nghe tiếng động từ `SoundEventBus` hoặc thấy vật cản bị dịch chuyển -> hiện dấu `?`, đi tới vị trí phát ra tiếng động và ngó xung quanh 5s.
   - `CHASE`: Khi thấy chuột trong tầm nhìn (`Area3D` hình nón + `RayCast3D` kiểm tra không bị tường/tủ che) -> hiện dấu `!`, hú còi/lẩm bẩm và đuổi theo tốc độ cao. Nếu chạm vào chuột -> Trigger Caught/Game Over.
   - `SEARCH`: Khi mất dấu chuột (chuột chui vào gầm tủ hoặc khuất tầm nhìn đủ lâu) -> lùng sục khu vực cuối cùng thấy chuột rồi quay lại lịch trình.
4. **Hệ thống Mouse Sense (Giác quan chuột — `MouseSenseUI.gd`):**
   - Tính khoảng cách và hướng từ Chuột tới Đầu bếp (kể cả xuyên tường).
   - **Chỉ báo trực quan trên HUD:**
     - Vòng cung/mũi tên cảnh báo hướng ở rìa màn hình (nhấp nháy theo hướng đầu bếp).
     - Màu sắc & tốc độ nhịp đập theo trạng thái AI: Trắng/Nhẹ (gần nhưng chưa thấy) -> Vàng (Nghi ngờ `?`) -> Đỏ + Rung nhẹ màn hình + Tiếng tim đập dồn dập (Đang đuổi `!`).

**Tiêu chí hoàn thành Giai đoạn 3:** Đầu bếp đi đúng lịch trình lặp lại; chuột gây ồn hoặc lọt vào tầm nhìn là đầu bếp phản ứng rõ ràng; người chơi luôn cảm nhận được vị trí và mức nguy hiểm của đầu bếp qua Mouse Sense trước khi bị tóm.

---

### Giai đoạn 4: Thông Tin, Giải Đố & Các Lối Thoát (Tuần 5–6)
> **Mục tiêu:** Tạo vòng lặp gameplay hoàn chỉnh (30–60 phút/run hoặc bản test ngắn 10–15 phút).

1. **Hệ thống Manh mối & Nghe lén:**
   - **Giấy Note (`NoteItem.gd`):** Dán trên tủ lạnh, bàn bếp. Tương tác để mở UI đọc ảnh/text (chứa lịch trình Chef, mật mã khóa, gợi ý lối thoát bí mật).
   - **Nghe lén (`EavesdropZone`):** Khi chuột nấp đủ gần Chef lúc Chef đang lẩm bẩm/nói chuyện điện thoại -> hiện phụ đề gợi ý ở góc dưới màn hình.
   - **Onboarding lần chết đầu tiên:** Chết lần đầu kích hoạt đoạn thoại ngắn gợi ý người chơi đi tìm tờ lịch trình (Timetable) trong bếp.
2. **Thiết kế ít nhất 2 Lối Thoát & Ending:**
   - **Lối thoát 1 (Dễ — Khe cửa sau):** Mở sẵn hoặc mở rất dễ. Nếu thoát khi chưa đủ chỉ tiêu đồ ăn -> **Bad Ending** (Chuột vẫn đói, gợi ý quay lại lấy thêm).
   - **Lối thoát 2 (Khó — Ống thông gió trên cao / Cửa sổ):** Cần giải đố (ví dụ: đẩy đồ leo lên kệ + gặm dây lưới thông gió) và mang đủ lượng đồ ăn -> **Good / True Ending**.
3. **Vùng tập kết đồ ăn (Stash Zone - tùy chọn cân bằng):** Cho phép chuột tha đồ về gần lối thoát rồi quay lại lấy tiếp để giảm ức chế khi mất hết nếu chết giữa chừng (hoặc giữ nguyên luật chết mất hết cho đúng tinh thần roguelite-stealth — sẽ chốt khi playtest).

---

### Giai đoạn 5: Thay Art, Âm Thanh, UI & Đóng Gói MVP (Tuần 6–8)
- [ ] Thay thế các khối greybox bằng model 3D bếp (tủ, bếp ga, bồn rửa, bàn ăn, đồ dùng).
- [ ] Gắn sprite sheet 2D chính thức cho Chuột (Idle, Walk, Run, Crouch, Drag, Jump) và Đầu bếp (Walk, Idle/Cook, Suspicious, Chase).
- [ ] Gắn đầy đủ SFX: tiếng bước chân nặng của đầu bếp (nghe rõ độ xa gần 3D), tiếng tim đập Mouse Sense, tiếng gặm, tiếng kéo đồ, tiếng lẩm bẩm.
- [ ] Hoàn thiện Menu chính, Pause Menu (Chỉnh độ nhạy chuột, âm lượng), Màn hình thống kê cuối run (Thời gian, Số đồ ăn, Ending đạt được).
- [ ] Playtest tổng thể với người chơi ngoài để chỉnh lại tốc độ chạy/kéo, thời gian dừng của Chef và độ dễ đọc của manh mối.

---

## Phần 4: Quy Trình Làm Việc Chung Giữa Bạn & AI

1. **Mỗi lần làm 1 tính năng nhỏ** (theo checklist từ Giai đoạn 0 -> 5), không làm dồn một lúc quá nhiều thứ.
2. Mình viết code/scene và hướng dẫn bạn mở file nào trong Godot.
3. Bạn bấm **F5 (Run Project)** để test thử trên máy.
4. Nếu có lỗi đỏ ở tab **Output / Debugger** hoặc cảm giác điều khiển chưa ổn, bạn copy dòng lỗi hoặc chụp màn hình gửi lại mình -> mình sửa ngay.
5. Xong mỗi mốc ổn định, mình sẽ commit & push lên GitHub để luôn có bản backup an toàn.
