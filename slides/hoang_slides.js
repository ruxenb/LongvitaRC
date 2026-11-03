// Longvita / Hoang: generated presentation (no fabricated screenshots).
// Run (with Node.js on PATH): node slides/hoang_slides.js
// Requires pptxgenjs installed to D:\Tools\LongvitaPptx.
const path = require('path');
let pptxgen;
try { pptxgen = require('pptxgenjs'); }
catch (_) { pptxgen = require('D:\\Tools\\LongvitaPptx\\node_modules\\pptxgenjs'); }
const pptx = new pptxgen();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'Longvita team — Hoang DV';
pptx.subject = 'PRM393 Lab 3 implementation evidence / no live demo claims';
pptx.title = 'Longvita — Hoang: 3 Flows, Firebase Data and Verification';
pptx.company = 'Longvita';
pptx.lang = 'vi-VN';

const C = { cream: 'F6F1E7', green: '476429', dark: '2F3B2A',
  muted: '5C6B53', light: 'E4F2DA', white: 'FFFFFF',
  edge: 'DCCDB0', red: 'BA1A1A', gray: 'E4E2DB' };
const W = 13.333, H = 7.5;
function rect(slide,x,y,w,h,fill,r=0.16,line=null) {
  slide.addShape(pptx.ShapeType.roundRect,{
    x,y,w,h,rectRadius:r,rotate:0,
    radius:r,fill:{color:fill},
    line:line?{color:line,width:0.8}:{color:fill,transparency:100},
  });
}
function txt(slide,text,x,y,w,h,opt={}) {
  const base={x,y,w,h,fontFace:'Aptos',fontSize:14,color:C.dark,
    breakLine:false,margin:0,valign:'mid',fit:'shrink',bold:false,...opt};
  slide.addText(text,base);
}
function bg(slide){ slide.background = {color:C.cream}; }
function hdr(slide,page,title,subtitle){
  bg(slide); slide.addShape(pptx.ShapeType.rect,{x:0,y:0,w:W,h:0.14,
    fill:{color:C.green},line:{color:C.green}});
  txt(slide,'LONGVITA  /  PRM393',0.55,0.27,5.0,0.3,
      {fontSize:11,bold:true,color:C.green,charSpacing:1.5});
  txt(slide,title,0.55,0.78,12.1,0.67,
      {fontFace:'Aptos Display',fontSize:30,bold:true,color:C.dark});
  txt(slide,subtitle,0.58,1.5,11.9,0.45,{fontSize:14,color:C.muted});
  slide.addShape(pptx.ShapeType.line,{x:0.55,y:7.07,w:12.2,h:0,
    line:{color:C.edge,width:1}});
  txt(slide,'Hoàng DV • 04/11/2026 • Status: 305 tests passed / acceptance pending',
      0.58,7.12,11.8,0.22,{fontSize:9,color:C.muted});
  txt(slide,String(page).padStart(2,'0') + ' / 04',
      12.02,7.11,0.65,0.25,{fontSize:10,bold:true,color:C.green,align:'right'});
}
function heading(slide,text,x,y,w) {
  txt(slide,text,x,y,w,0.32,{fontSize:15,bold:true,color:C.green});
}
function bullet(slide,items,x,y,w,h,fontSize=12.5){
  txt(slide,items.map(a=>'• '+a).join('\n'),x,y,w,h,
    {fontSize,breakLine:false,valign:'top',paraSpaceAfterPt:8,
      color:C.dark,margin:0.04});
}
function pill(slide,text,x,y,w,fill=C.light){
  rect(slide,x,y,w,0.4,fill);
  txt(slide,text,x+0.1,y+0.08,w-0.2,0.22,
      {fontSize:11,bold:true,color:C.green,align:'center'});
}

// Slide 1
{
  const s=pptx.addSlide();
  hdr(s,1,'Từ Figma Lab 2 đến ứng dụng Flutter thật',
      'Vai trò Hoàng: Data Service • MVVM • 3 User Flows • A11y • ARTEMIS');
  rect(s,0.55,2.05,7.6,3.65,C.white);
  heading(s,'KIẾN TRÚC DỮ LIỆU',0.83,2.28,6.9);
  const nodes=[
    ['Screens S01–S10',0.83],
    ['ViewModels + ViewState',2.52],
    ['IDataService',4.57],
    ['Cloud Firestore',6.17],
  ];
  nodes.forEach((t,i)=>{
    const x=t[1];
    rect(s,x,3.02,i===1?1.72:1.45,0.96,i===3?C.light:C.cream,0.14,C.edge);
    txt(s,t[0],x+0.10,3.25,(i===1?1.72:1.45)-0.2,0.48,
      {fontSize:13,bold:true,align:'center'});
    if(i<3) {
      s.addShape(pptx.ShapeType.chevron,{x:x+(i===1?1.76:1.5),y:3.32,
        w:0.20,h:0.36,fill:{color:C.green},line:{color:C.green}});
    }
  });
  txt(s,'Source of truth: users • recipes • meal_plans • shopping_lists',
      0.88,4.42,6.95,0.44,{fontSize:13,color:C.muted});
  txt(s,'Không dùng món mẫu khi Firestore trống. Lỗi được phân loại và có Retry.',
      0.88,4.95,6.85,0.42,{fontSize:12,bold:true,color:C.green});
  rect(s,8.4,2.05,4.36,3.65,C.light);
  heading(s,'PHẠM VI HOÀNG',8.68,2.32,3.75);
  bullet(s,[
    '10 màn hình kế thừa: S01–S10',
    'Ba luồng nghiệp vụ đã triển khai',
    'Bản nháp thực đơn 7 ngày',
    'Checklist theo UID + plan ID',
    'Google/Firebase integration cần E2E',
  ],8.67,2.93,3.72,2.4,13);
  pill(s,'Figma Lab 2 đóng băng theo quyết định nhóm',1.13,6.1,6.9,C.gray);
}

// Slide 2
{
  const s=pptx.addSlide();
  hdr(s,2,'Flow 1 — Tạo và lưu thực đơn 7 ngày',
      'S01 → S02 → S03 → S04 → S10 | Tuổi/cân nặng do người dùng nhập');
  const steps=[
    ['S01','Trang chủ','Bắt đầu'],
    ['S02','Sở thích','Validate input'],
    ['S03','Tạo kế hoạch','Loading/Retry'],
    ['S04','Kết quả','7 ngày + Save'],
    ['S10','Đã lưu','Firestore plans'],
  ];
  steps.forEach((a,i)=>{
    const x=0.55+i*2.57;
    rect(s,x,2.35,2.22,1.42,i===4?C.light:C.white,0.16,C.edge);
    txt(s,a[0],x+0.2,2.52,1.8,0.32,{fontSize:20,bold:true,color:C.green});
    txt(s,a[1],x+0.2,2.94,1.8,0.34,{fontSize:14,bold:true});
    txt(s,a[2],x+0.2,3.32,1.8,0.2,{fontSize:10.5,color:C.muted});
    if(i<4) s.addShape(pptx.ShapeType.chevron,{x:x+2.28,y:2.84,
      w:0.21,h:0.36,fill:{color:C.green},line:{color:C.green}});
  });
  rect(s,0.55,4.15,5.94,1.73,C.white);
  heading(s,'HAPPY PATH',0.84,4.41,4.8);
  bullet(s,[
    'Chọn công thức từ recipes thật',
    'Lưu vào meal_plans theo uid',
    'Mở lại bản kế hoạch từ S10',
  ],0.83,4.85,5.28,0.9,12);
  rect(s,6.76,4.15,6.0,1.73,C.white);
  heading(s,'ERROR / RECOVERY PATH',7.02,4.41,5.4);
  bullet(s,[
    'Không có recipes → Empty rõ ràng',
    'Mất mạng → Error + Retry/Back',
    'Lưu lỗi → vẫn giữ thực đơn đang xem',
  ],7.02,4.85,5.3,0.95,12);
  txt(s,'Kiểm thử ViewModel bằng fake service; chưa chứng minh được dữ liệu trên Firebase thật.',
      0.66,6.37,12.0,0.38,{fontSize:12,color:C.muted});
}

// Slide 3
{
  const s=pptx.addSlide();
  hdr(s,3,'Flow 2 + Flow 3 — Đi chợ và thay món',
      'Các thao tác quan trọng: sửa số lượng, Undo, persistence, thay món không mất dữ liệu');
  rect(s,0.55,2.12,6.0,3.95,C.white);
  heading(s,'FLOW 2  |  S04 → S07 → S08',0.86,2.42,5.2);
  bullet(s,[
    'Gộp nguyên liệu theo tên và đơn vị',
    'S07 dialog: số lượng > 0; âm/0 báo lỗi',
    'Xóa nhầm: SnackBar “Hoàn tác”',
    'S08: checkbox lưu lên shopping_lists',
    'Lưu theo tài khoản + kế hoạch, có Retry',
  ],0.87,3.02,5.25,2.3,15);
  pill(s,'State: Loading / Empty / Error / Data',0.9,5.47,5.15);
  rect(s,6.78,2.12,5.98,3.95,C.white);
  heading(s,'FLOW 3  |  S04 → S05 → S06/S09',7.07,2.42,5.35);
  bullet(s,[
    'Chi tiết công thức từ Firestore',
    'Xem nguồn ghi nhận ở S09, không bịa trang sách',
    'Lọc món thay thế theo đạm và kcal',
    'Không có món → quay về S02',
    'Update lỗi → giữ món gốc, Retry',
  ],7.07,3.02,5.28,2.3,14.3);
  pill(s,'Không tự ghi đè kế hoạch khi cloud lỗi',7.08,5.47,5.17);
  txt(s,'Nguyên tắc an toàn: không có dữ liệu thật thì hiển thị Empty, không tạo dữ liệu giả.',
      0.66,6.37,11.9,0.34,{fontSize:12,bold:true,color:C.green});
}

// Slide 4
{
  const s=pptx.addSlide();
  hdr(s,4,'Đối chiếu Figma → Flutter và trạng thái QA',
      'Báo cáo kỹ thuật trung thực: chỉ ghi nhận những gì đã kiểm chứng');
  rect(s,0.55,2.02,5.96,2.65,C.white);
  heading(s,'FIGMA LAB 2 (BẢN ĐÓNG BĂNG)',0.85,2.26,5.30);
  bullet(s,[
    '10 màn S01–S10',
    'Flow 1: lập thực đơn',
    'Flow 2: nguyên liệu / mua sắm',
    'Flow 3: công thức / thay món',
    'Trang Sign-in + Profile bổ sung bởi Charlie',
  ],0.85,2.72,5.12,1.66,12.2);
  rect(s,6.77,2.02,5.99,2.65,C.light);
  heading(s,'FLUTTER HIỆN TẠI',7.07,2.26,5.29);
  bullet(s,[
    'Đã có 10 screen class + navigation',
    'S02/03/07 xác thực input và Retry',
    'Firestore services + typed ViewState',
    'Không hardcode demo recipes',
    'Chờ hình chụp Android để nghiệm thu fidelity',
  ],7.08,2.72,5.20,1.70,12.2);
  rect(s,0.55,4.94,5.96,1.42,C.white);
  heading(s,'ĐÃ CÓ BẰNG CHỨNG',0.85,5.16,5.25);
  txt(s,'305/305 Flutter tests • 6/6 A11y widget tests\n360/412dp • scale 1x/2x • flutter analyze sạch',
      0.86,5.62,5.20,0.48,{fontSize:13,bold:true});
  rect(s,6.77,4.94,5.99,1.42,C.white);
  heading(s,'CÒN CHỜ XÁC MINH',7.08,5.16,5.2);
  txt(s,'Android device + ARTEMIS • Firestore live/rules\nFirebase SHA, PR re-review • screenshot & demo video',
      7.08,5.61,5.18,0.55,{fontSize:12.6,color:C.red,bold:true});
}
pptx.writeFile({fileName:path.join(__dirname, 'Longvita_Hoang_4_Slides_20261104.pptx')});
