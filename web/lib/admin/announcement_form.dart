import 'package:flutter/material.dart';
import 'package:longvita_admin/admin/announcement_viewmodel.dart';
import 'package:longvita_core/longvita_core.dart';
import 'package:provider/provider.dart';

/// Vietnamese compose/preview UI; publishing and retries belong to the model.
class AnnouncementForm extends StatefulWidget {
  const AnnouncementForm({super.key});

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
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
        title: const Text('Phát thông báo?'),
        content: const Text(
          'Thông báo sẽ hiển thị trong Hộp thư thông báo ở Trang chủ '
          'của tất cả người dùng đã đăng nhập. Bạn muốn tiếp tục?',
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
  Widget build(BuildContext context) => VietnameseUi(
    child: Consumer<AnnouncementViewModel>(
      builder: (context, model, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  headingLevel: 1,
                  child: Text('Thông báo', style: AppTypography.headingM),
                ),
                const SizedBox(height: AppSpacing.s8),
                const Text(
                  'Soạn tin gửi đến hộp thư Trang chủ trên ứng dụng di động.',
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
                          labelText: 'Tiêu đề',
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
                          labelText: 'Nội dung',
                          hintText: 'Viết nội dung cần gửi đến người dùng',
                          alignLabelWithHint: true,
                          counterText:
                              '${model.content.trim().runes.length}/2000',
                          errorText: model.contentError,
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
                              : 'Phát thông báo',
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
                          'Xem trước trên hộp thư',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
