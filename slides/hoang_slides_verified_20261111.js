const pptxgen=require('D:\\Tools\\LongvitaPptx\\node_modules\\pptxgenjs');
const path=require('path');
const fs=require('fs');
const pptx=new pptxgen();
pptx.layout='LAYOUT_WIDE';
pptx.author='Longvita team - Hoang';
pptx.subject='PRM393 Hoang Mobile real device evidence 11 November 2026';
pptx.title='Longvita - minh chung task Hoang';
pptx.company='Longvita';pptx.lang='vi-VN';
pptx.theme={headFontFace:'Aptos Display',bodyFontFace:'Aptos',lang:'vi-VN'};
const root=path.resolve(__dirname,'..');
const ev=path.join(root,'evidence','hoang','android-a15-20261111');
const out=path.join(__dirname,'Longvita_Hoang_4_Slides_Verified_20261111.pptx');
const C={ivory:'F6F1E7',green:'476429',forest:'2F3B2A',sage:'E4F2DA',white:'FFFFFF',muted:'5C6B53',edge:'DCCDB0',peach:'F4DFC9',grey:'E4E2DB',orange:'AC6948'};
const SW=13.333, SH=7.5, Shape=pptx.ShapeType;
const txt=(s,v,x,y,w,h,o={})=>s.addText(v,{x,y,w,h,fontFace:'Aptos',fontSize:14,color:C.forest,margin:0,breakLine:false,fit:'shrink',valign:'mid',...o});
const box=(s,x,y,w,h,fill=C.white,rr=true)=>s.addShape(rr?Shape.roundRect:Shape.rect,{x,y,w,h,rectRadius:0.1,fill:{color:fill},line:{color:fill,transparency:100}});
const line=(s,x,y,w,h,color=C.edge)=>s.addShape(Shape.line,{x,y,w,h,line:{color,width:1}});
function base(n,title,sub){
 const s=pptx.addSlide();s.background={color:C.ivory};
 box(s,0,0,SW,0.12,C.green,false);
 txt(s,'LONGVITA  /  PRM393  /  HOÀNG',0.65,0.29,8,0.25,{color:C.green,bold:true,fontSize:11,charSpacing:1.2});
 txt(s,title,0.65,0.73,12,0.64,{fontSize:29,bold:true,fontFace:'Aptos Display'});
 txt(s,sub,0.68,1.4,11.9,0.43,{fontSize:12.6,color:C.muted});
 line(s,0.65,7.05,12.05,0);
 txt(s,'Bằng chứng thật từ Samsung A15 • 11/11/2026 • Chưa phải nghiệm thu 100%',0.68,7.12,10.5,0.23,{fontSize:9,color:C.muted});
 txt(s,String(n).padStart(2,'0')+' / 04',11.7,7.1,0.92,0.25,{fontSize:10,bold:true,color:C.green,align:'right'});
 return s;
}
function label(s,val,x,y,w,fill=C.sage){
 box(s,x,y,w,0.4,fill);txt(s,val,x+0.1,y+0.04,w-0.2,0.27,{fontSize:11.7,bold:true,color:C.green,align:'center'});
}
function photo(s,filename,x,y,w,h){
 const full=path.join(ev,filename);
 if(!fs.existsSync(full))throw new Error('Missing evidence '+filename);
 s.addImage({path:full,x,y,w,h});
}
function item(s,k,v,x,y,w){
 box(s,x,y,w,0.84,C.white);
 txt(s,k,x+0.15,y+0.12,w-0.3,0.26,{fontSize:11,bold:true,color:C.green});
 txt(s,v,x+0.15,y+0.43,w-0.3,0.28,{fontSize:12,color:C.forest});
}
// Slide 1
{
 const s=base(1,'Longvita Mobile — phần triển khai của Hoàng','Kiến trúc dữ liệu Firestore, 10 màn Lab 2 và ba luồng nghiệp vụ kế thừa.');
 label(s,'KIẾN TRÚC MVVM',0.73,2.06,2.35);
 const names=[['Flutter UI','S01 – S10'],['ViewModel','Loading / Empty / Error / Data'],['IDataService','Giao diện dịch vụ'],['Cloud Firestore','Nguồn dữ liệu']];
 for(let i=0;i<names.length;i++){
   const x=0.75+i*3.1;
   box(s,x,2.82,2.65,1.4,i===3?C.sage:C.white);
   txt(s,names[i][0],x+0.18,3.07,2.3,0.38,{fontSize:18,bold:true,align:'center'});
   txt(s,names[i][1],x+0.15,3.56,2.35,0.43,{fontSize:11.5,color:C.muted,align:'center'});
   if(i<3)txt(s,'→',x+2.68,3.24,0.4,0.43,{fontSize:25,color:C.green,align:'center'});
 }
 item(s,'FLOW 1  /  S01–S04–S10','Tạo và lưu thực đơn tuần',0.75,4.7,3.94);
 item(s,'FLOW 2  /  S07–S08','Nguyên liệu, chỉnh lượng và đi chợ',4.76,4.7,3.94);
 item(s,'FLOW 3  /  S05–S06–S09','Công thức, thay món và nguồn sách',8.77,4.7,3.79);
 box(s,0.75,5.83,11.82,0.67,C.sage);
 txt(s,'Đã đo kiểm Mobile: Flutter Analyze 0 vấn đề   |   Flutter Test 487/487 đạt   |   Android APK build thành công',0.95,6.03,11.39,0.25,{fontSize:14.2,bold:true,color:C.green,align:'center'});
}
// Slide 2
{
 const s=base(2,'Flow 1 — tạo và lưu thực đơn tuần','S01 → S02 → S03 → S04; thao tác trên tài khoản thật, không đưa recipe mock vào Firestore.');
 const pics=[
 ['S02 · TÙY CHỌN','s02-options-no-pii.png'],
 ['S03 · TẠO THỰC ĐƠN','s03-setup-no-pii.png'],
 ['S04 · KẾT QUẢ','s04-generated-preview-before-polish.png'],
 ];
 for(let i=0;i<3;i++){
   const x=0.78+i*4.17;
   box(s,x,2.03,3.78,3.8,C.white);
   label(s,pics[i][0],x+0.16,2.16,3.4);
   photo(s,pics[i][1],x+0.28,2.72,3.2,2.77);
 }
 box(s,0.79,5.98,11.75,0.77,C.sage);
 txt(s,'Khi lưu S04, ứng dụng báo: “Đã lưu kế hoạch lên Firestore.” Chưa có ảnh S10 read-back sau khởi động lại.',1.02,6.12,11.24,0.5,{fontSize:13,bold:true,color:C.green,align:'center'});
}
// Slide 3
{
 const s=base(3,'Flow 3 — xử lý trạng thái rỗng có hướng phục hồi','S05 chi tiết món → S06 không có lựa chọn thay thế → quay lại S02 điều chỉnh sở thích.');
 box(s,0.8,2.05,3.38,4.74,C.white);
 photo(s,'s06-empty-and-retry.png',0.93,2.2,3.11,4.4);
 box(s,4.52,2.05,4.1,4.74,C.white);
 label(s,'ĐÃ KIỂM TRA THỰC TẾ',4.75,2.32,3.61);
 txt(s,'1. Món từ dữ liệu hệ thống được mở trên màn Chi tiết công thức.',4.8,3.0,3.49,0.76,{fontSize:16,bold:true});
 txt(s,'2. Không có món thay thế phù hợp: hiển thị trạng thái rỗng và nút Thử lại.',4.8,4.04,3.49,0.85,{fontSize:16});
 txt(s,'3. Bấm Điều chỉnh sở thích: ứng dụng điều hướng về S02.',4.8,5.21,3.47,0.88,{fontSize:16,color:C.green,bold:true});
 box(s,8.95,2.05,3.56,4.74,C.white);
 label(s,'ĐƯỜNG QUAY LẠI S02',9.16,2.31,3.14);
 photo(s,'s06-recovery-to-s02-no-pii.png',9.22,2.9,3.05,2.93);
 txt(s,'Không thay món khi dữ liệu chưa đủ; giữ món gốc.',9.19,5.97,3.1,0.55,{fontSize:11.6,color:C.muted,align:'center'});
}
// Slide 4
{
 const s=base(4,'Chất lượng đã đo và giới hạn nghiệm thu','Chỉ ghi nhận kết quả đã kiểm; không đồng nhất unit/widget test với ARTEMIS và Firebase cross-role.');
 box(s,0.75,2.08,5.76,4.57,C.white);
 txt(s,'487 / 487',1.12,2.42,5.04,1.15,{fontSize:48,bold:true,color:C.green,align:'center'});
 txt(s,'Bài kiểm thử Flutter đạt',1.2,3.64,4.87,0.39,{fontSize:17,bold:true,align:'center'});
 item(s,'MOBILE ANALYZE','0 vấn đề',1.02,4.35,2.44);
 item(s,'ANDROID DEBUG APK','Build thành công',3.66,4.35,2.53);
 txt(s,'Samsung A15: đã chạy flow, lưu Firestore và có ảnh thật; ảnh S04 hiện tại là bản trước sửa UI.',1.08,5.67,5.13,0.62,{fontSize:12.5,color:C.muted});
 box(s,6.78,2.08,5.72,4.57,C.white);
 label(s,'CẦN NGHIỆM THU THÊM',7.06,2.32,4.98,C.peach);
 const points=[
  'ARTEMIS: ít nhất 3 lượt thực cho mỗi ca.',
  'Web staff duyệt → Mobile nhận trạng thái (3 lần).',
  'S07/S08 và S10: mở lại dữ liệu trên thiết bị.',
  'Xuất PDF thật, metadata, Analytics / Crashlytics.',
  'Phê duyệt recipe, 10 màn Figma và video demo.'
 ];
 points.forEach((v,i)=>{txt(s,(i+1)+'.',7.13,2.98+i*0.59,0.36,0.35,{fontSize:13.4,bold:true,color:C.orange});txt(s,v,7.49,2.96+i*0.59,4.66,0.49,{fontSize:12.6});});
 txt(s,'Kết luận: đã có bằng chứng kỹ thuật và Android, chưa đủ cơ sở ký nhận 100% tất cả task.',7.12,6.11,5.02,0.38,{fontSize:11.2,bold:true,color:C.orange});
}
pptx.writeFile({fileName:out}).then(()=>console.log('CREATED',out,'size',fs.statSync(out).size)).catch(e=>{console.error(e);process.exit(1)});
