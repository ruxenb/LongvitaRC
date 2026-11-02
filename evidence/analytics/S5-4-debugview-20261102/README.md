# S5-4 — `login`, `logout` trên DebugView, 02/11/2026

Nhánh `feature/charlie-profile-01` tại `32aa667`, bản debug. Project `longvita-8da7e`, app `vn.edu.fpt.longvita`, AVD `LocalMate_API_35`, tài khoản Google thật của Charlie.

| File | Nội dung |
|---|---|
| `debugview-login-logout.jpg` | Dòng thời gian có `login` rồi `logout`, Top events: mỗi sự kiện 1 lần |
| `debugview-second-login.jpg` | Sau một lần đăng nhập nữa: `login` 2, `logout` 1 |
| `logcat-events.txt` | Dòng log của thiết bị cho hai sự kiện, gồm tham số |

## Kết quả

| Thao tác | Sự kiện | Tham số | Kết quả |
|---|---|---|---|
| Đăng nhập Google | `login` | `method=google` | Lên DebugView, 1 lần cho mỗi lần đăng nhập |
| Đăng xuất từ Profile | `logout` | Không có tham số riêng | Lên DebugView, 1 lần |

`logcat-events.txt` chỉ phủ `logout` và lần `login` thứ hai, vì log được bật verbose sau lần đăng nhập đầu. Mỗi lần đăng nhập đều có cửa sổ chọn tài khoản, nên hai `login` là hai lần đăng nhập thật, không phải gửi trùng.

## Tái lập

```bash
adb shell setprop debug.firebase.analytics.app vn.edu.fpt.longvita
```

Mở lại app, đăng nhập, đăng xuất, rồi xem Analytics > DebugView trên Console. Tắt bằng:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

## Chưa kiểm chứng

- `export_report`: chỉ gửi khi upload thành công, mà project chưa có Storage, chờ DEC-01. Tham số trong code có test bằng fake.
- `generate_meal_plan`: không gửi cho đến khi màn S02 cung cấp `eating_window_hours`.
- Dữ liệu trên báo cáo Analytics chuẩn: chỉ mới xem DebugView.
- Máy thật.
