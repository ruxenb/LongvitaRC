import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longvita_admin/admin/announcement_viewmodel.dart';
import 'package:longvita_core/longvita_core.dart';
import 'package:provider/provider.dart';

/// Screen with two dedicated tabs:
/// Tab 1: In-App Announcement (Home Inbox via Firestore stream)
/// Tab 2: Push Notification (System Tray / Lock Screen via FCM Dispatcher)
class AnnouncementForm extends StatelessWidget {
  const AnnouncementForm({super.key});

  @override
  Widget build(BuildContext context) => VietnameseUi(
    child: DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s24,
              right: AppSpacing.s24,
              top: AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  headingLevel: 1,
                  child: Text('Trung tâm Thông báo', style: AppTypography.headingM),
                ),
                const SizedBox(height: AppSpacing.s12),
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.actionPrimary,
                  labelColor: AppColors.actionPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.inbox_outlined),
                      text: 'Bản tin trong ứng dụng (Trang chủ)',
                    ),
                    Tab(
                      icon: Icon(Icons.notifications_active_outlined),
                      text: 'Thông báo đẩy (Push Notification - FCM)',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _InAppAnnouncementView(),
            _PushNotificationView(),
          ],
        ),
      ),
    ),
  );
}

/// Tab 1: In-App Announcement view (preserves existing AnnouncementForm logic)
class _InAppAnnouncementView extends StatefulWidget {
  const _InAppAnnouncementView();

  @override
  State<_InAppAnnouncementView> createState() => _InAppAnnouncementViewState();
}

class _InAppAnnouncementViewState extends State<_InAppAnnouncementView> {
  final _title = TextEditingController();
  final _content = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _confirm(AnnouncementViewModel model) async {
    if (!model.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Đóng',
      builder: (context) => AlertDialog(
        title: const Text('Phát thông báo trong app?'),
        content: const Text(
          'Thông báo sẽ hiển thị trong Hộp thư thông báo ở Trang chủ '
          'của các tài khoản được chọn. Bạn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý phát'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) await model.publish();
  }

  @override
  Widget build(BuildContext context) => Consumer<AnnouncementViewModel>(
    builder: (context, model, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Soạn tin tức / bài đăng hiển thị trực tiếp trong mục Hộp thư Trang chủ trên ứng dụng.',
              ),
              const SizedBox(height: AppSpacing.s24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('announcement-title'),
                      controller: _title,
                      readOnly: !model.editable,
                      onChanged: model.changeTitle,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề bản tin',
                        hintText: 'Nhập tiêu đề thông báo',
                        counterText: '${model.title.trim().runes.length}/120',
                        errorText: model.titleError,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    TextField(
                      key: const ValueKey('announcement-content'),
                      controller: _content,
                      readOnly: !model.editable,
                      onChanged: model.changeContent,
                      minLines: 5,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'Nội dung chi tiết',
                        hintText: 'Viết nội dung bản tin cần gửi đến người dùng',
                        alignLabelWithHint: true,
                        counterText: '${model.content.trim().runes.length}/2000',
                        errorText: model.contentError,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Text('Đối tượng nhận', style: AppTypography.labelStrong),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final entry in const {
                          'admin': 'Admin',
                          'staff': 'Staff',
                          'user': 'User',
                        }.entries)
                          FilterChip(
                            key: ValueKey('announcement-role-${entry.key}'),
                            label: Text(entry.value),
                            selected: model.targetRoles.contains(entry.key),
                            onSelected: model.editable
                                ? (selected) => model.toggleTargetRole(
                                    entry.key,
                                    selected,
                                  )
                                : null,
                          ),
                      ],
                    ),
                    if (model.showValidation && model.targetRoles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.s8),
                        child: Text(
                          'Vui lòng chọn ít nhất một nhóm người nhận.',
                          style: TextStyle(color: AppColors.feedbackError),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s24),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        model.published
                            ? 'Đã phát thông báo. Hộp thư Mobile sẽ cập nhật khi có kết nối.'
                            : model.phase ==
                                  AnnouncementPhase.awaitingConfirmation
                            ? 'Chưa có xác nhận từ máy chủ. Đang chờ kết quả; vui lòng không phát lại.'
                            : model.error ??
                                  (model.phase == AnnouncementPhase.failed
                                      ? 'Chưa phát được thông báo.'
                                      : model.busy
                                      ? 'Đang gửi thông báo đến máy chủ…'
                                      : 'Thông báo sẽ được gửi tới tất cả người dùng đã đăng nhập.'),
                        style: model.error == null
                            ? AppTypography.body
                            : AppTypography.body.copyWith(
                                color: AppColors.feedbackError,
                              ),
                      ),
                    ),
                    if (model.phase == AnnouncementPhase.failed) ...[
                      const SizedBox(height: AppSpacing.s8),
                      const Text(
                        'Nội dung được giữ nguyên khi thử lại để tránh phát trùng.',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    if (model.published)
                      AppButton(
                        text: 'Soạn thông báo mới',
                        onPressed: () {
                          model.startNew();
                          if (model.editable) {
                            _title.clear();
                            _content.clear();
                          }
                        },
                      )
                    else
                      AppButton(
                        text: model.phase == AnnouncementPhase.failed
                            ? 'Thử phát lại'
                            : 'Phát thông báo trong app',
                        icon: Icons.send_outlined,
                        isLoading: model.busy,
                        loadingText:
                            model.phase ==
                                AnnouncementPhase.awaitingConfirmation
                            ? 'Đang chờ xác nhận…'
                            : 'Đang phát…',
                        onPressed: model.busy ? null : () => _confirm(model),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      header: true,
                      headingLevel: 2,
                      child: Text(
                        'Xem trước trên hộp thư Trang chủ',
                        style: AppTypography.labelStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      model.title.trim().isEmpty
                          ? 'Tiêu đề thông báo'
                          : model.title.trim(),
                      style: AppTypography.labelStrong,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      model.content.trim().isEmpty
                          ? 'Nội dung bạn soạn sẽ xuất hiện tại đây.'
                          : model.content.trim(),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Người đăng: ${model.role == 'admin' ? 'Quản trị viên' : 'Nhân viên'}',
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Người nhận: ${_targetRoleLabels(model.targetRoles)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _targetRoleLabels(Set<String> roles) {
    if (roles.length == AnnouncementModel.supportedTargetRoles.length) {
      return 'Tất cả tài khoản';
    }
    const labels = {'admin': 'Admin', 'staff': 'Staff', 'user': 'User'};
    return roles.map((role) => labels[role] ?? role).join(', ');
  }
}

/// Tab 2: Push Notification view (Direct FCM Push to Device Notification Shade)
class _PushNotificationView extends StatefulWidget {
  const _PushNotificationView();

  @override
  State<_PushNotificationView> createState() => _PushNotificationViewState();
}

class _PushNotificationViewState extends State<_PushNotificationView> {
  final _fcmTitle = TextEditingController();
  final _fcmBody = TextEditingController();
  final _recipientUid = TextEditingController();

  String _targetType = 'all'; // 'all', 'role', 'user'
  final Set<String> _selectedRoles = {'user'};
  bool _isSending = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _fcmTitle.dispose();
    _fcmBody.dispose();
    _recipientUid.dispose();
    super.dispose();
  }

  Future<void> _sendPushNotification() async {
    final title = _fcmTitle.text.trim();
    final body = _fcmBody.text.trim();

    if (title.isEmpty || body.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo.';
      });
      return;
    }

    if (_targetType == 'user' && _recipientUid.text.trim().isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Vui lòng nhập UID của người nhận.';
      });
      return;
    }

    if (_targetType == 'role' && _selectedRoles.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Vui lòng chọn ít nhất một vai trò nhận thông báo.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('fcm_broadcasts').add({
        'title': title,
        'body': body,
        'targetType': _targetType,
        'targetRoles': _selectedRoles.toList(),
        'recipientUid': _targetType == 'user' ? _recipientUid.text.trim() : null,
        'status': 'pending',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isSending = false;
          _isError = false;
          _statusMessage = 'Đã gửi yêu cầu Push Notification! Script Dispatcher sẽ bắn tới thiết bị trong giây lát.';
          _fcmTitle.clear();
          _fcmBody.clear();
          _recipientUid.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isError = true;
          _statusMessage = 'Lỗi khi gửi thông báo đẩy: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.s24),
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gửi thông báo đẩy tức thời (Push Notification qua FCM) ra ngoài màn hình khóa và khay hệ thống Android.',
            ),
            const SizedBox(height: AppSpacing.s24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _fcmTitle,
                    maxLength: 60,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề thông báo đẩy',
                      hintText: 'VD: Nhắc nhở bữa trưa dinh dưỡng',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TextField(
                    controller: _fcmBody,
                    maxLength: 200,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nội dung thông báo đẩy',
                      hintText: 'VD: Đã đến giờ chuẩn bị bữa trưa theo thực đơn tuần rồi!',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text('Hình thức gửi', style: AppTypography.labelStrong),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s12,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả người dùng (Broadcast)'),
                        selected: _targetType == 'all',
                        onSelected: (val) {
                          if (val) setState(() => _targetType = 'all');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Theo vai trò (Role)'),
                        selected: _targetType == 'role',
                        onSelected: (val) {
                          if (val) setState(() => _targetType = 'role');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Người dùng cụ thể (Theo UID)'),
                        selected: _targetType == 'user',
                        onSelected: (val) {
                          if (val) setState(() => _targetType = 'user');
                        },
                      ),
                    ],
                  ),
                  if (_targetType == 'role') ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text('Chọn vai trò nhận:', style: AppTypography.supporting),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      children: [
                        for (final role in ['user', 'staff', 'admin'])
                          FilterChip(
                            label: Text(role.toUpperCase()),
                            selected: _selectedRoles.contains(role),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRoles.add(role);
                                } else {
                                  _selectedRoles.remove(role);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                  if (_targetType == 'user') ...[
                    const SizedBox(height: AppSpacing.s16),
                    TextField(
                      controller: _recipientUid,
                      decoration: const InputDecoration(
                        labelText: 'Firebase Auth UID người nhận',
                        hintText: 'Nhập UID tài khoản cần nhận tin',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  if (_statusMessage != null) ...[
                    Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isError
                            ? AppColors.feedbackError
                            : AppColors.actionPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                  ],
                  AppButton(
                    text: 'Bắn thông báo đẩy (FCM)',
                    icon: Icons.send_to_mobile_outlined,
                    isLoading: _isSending,
                    onPressed: _isSending ? null : _sendPushNotification,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mô phỏng hiển thị trên khay thông báo Android (System Tray)',
                    style: AppTypography.labelStrong,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.eco,
                              size: 18,
                              color: AppColors.actionPrimary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Longvita',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• vừa xong',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fcmTitle.text.trim().isEmpty
                              ? 'Tiêu đề thông báo'
                              : _fcmTitle.text.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fcmBody.text.trim().isEmpty
                              ? 'Nội dung thông báo đẩy sẽ hiển thị ở đây trên màn hình điện thoại.'
                              : _fcmBody.text.trim(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
