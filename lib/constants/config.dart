class AppConfig {
  static const String supabaseUrl = 'https://qqffkaolnydtabrtijjt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxZmZrYW9sbnlkdGFicnRpamp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MDM5OTksImV4cCI6MjA4NzA3OTk5OX0.F136-HnjyzRSecrKTzR2p4sni9eewTjB_Bz2Q5s5Hlo';

  // 개발 중: PC와 폰이 같은 WiFi에 있어야 함
  // 배포 후: 'https://your-domain.com' 으로 교체
  static const String apiBaseUrl = 'http://192.168.0.6:3000';
}
