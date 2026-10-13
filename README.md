# لوحة تحليل المشاعر العربية (Flutter Web)

لوحة تحكم تتصل بالباك إند (NestJS) المنشور على Vercel:
`https://arabic-sentiment-back.vercel.app`

## الأقسام
| القسم | المسار المستخدم في الباك إند |
|---|---|
| نظرة عامة (كروت + رسم خطي + رسم دائري) | `GET /sentiment/stats` |
| تحليل مباشر | `POST /sentiment/analyze` |
| رفع ملفات (CSV/TXT) | قراءة محلية ثم `POST /sentiment/analyze-batch` دفعات من 20 نصاً مع شريط تقدم حقيقي |
| رفع ملفات (XLSX/XLS) | `POST /sentiment/analyze-file` (الحد الأقصى 4MB بسبب حد Vercel) |
| السجل (بحث + فلتر + ترقيم) | `GET /sentiment/logs?page&limit&label&search` |

## التشغيل محلياً
1. ثبّتي Flutter (3.22 أو أحدث) وتأكدي: `flutter doctor`
2. افتحي terminal داخل مجلد المشروع ونفّذي (مرة واحدة فقط، لتوليد مجلد web):
   ```bash
   flutter create . --platforms=web --project-name sentiment_dashboard
   flutter pub get
   ```
3. شغّلي:
   ```bash
   flutter run -d chrome
   ```

لتغيير رابط الباك إند بدون تعديل الكود:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://your-backend.vercel.app
```

## النشر على Vercel
Vercel لا يحتوي Flutter، لذلك نبني المشروع على جهازك ثم نرفع الناتج:
```bash
flutter build web --release
cd build/web
```
أنشئي داخل `build/web` ملفاً اسمه `vercel.json`:
```json
{ "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }] }
```
ثم:
```bash
npm i -g vercel
vercel --prod
```
(أول مرة سيسألك عن تسجيل الدخول واسم المشروع).

## هيكل المشروع (Feature-First)
```
lib/
  main.dart, app.dart, shell.dart      نقطة البداية والتنقل
  core/                                الإعدادات والثيم والتنسيق
  data/                                النماذج + عميل الـ API
  shared/                              ويدجتات مشتركة
  features/
    overview/                          الإحصائيات والرسوم
    analyze/                           التحليل المباشر
    bulk/                              رفع الملفات
    history/                           جدول السجل
```

## ملاحظات
- الباك إند يرجع تصنيفين فقط: `pos` و `neg` (لا يوجد محايد)، لذلك اللوحة تعرضهما فقط.
- الخط (IBM Plex Sans Arabic) يُحمَّل من Google Fonts أثناء التشغيل، فيحتاج إنترنت.
- أول طلب بعد فترة توقف قد يتأخر بضع ثوانٍ (Vercel + Neon يستيقظان من النوم).
