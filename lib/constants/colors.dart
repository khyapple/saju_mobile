import 'package:flutter/material.dart';

// ── 오행 (Five Elements) 기반 한국 전통 컬러 팔레트 ──

// 배경 / Background — 수(水) 검정
const kBgColor = Color(0xFF0D0D0D);
const kInk = Color(0xFF0D0D0D);

// 텍스트 — 금(金) 백색 계열
const kDark = Color(0xFFF2EFE8);

// 주요 강조색 — 토(土) 노랑
const kGold = Color(0xFFF5C800);
const kSecondaryGold = Color(0xFFD4AB00);

// 패널 / 카드
const kLightPanel = Color(0xFF1A1A1A);
const kMediumPanel = Color(0xFF242424);

// 보조 색상
const kTextMuted = Color(0xFF999999);
const kBorderColor = Color(0xFF333333);
const kErrorColor = Color(0xFFE8231A);

// 오행 색상 (Five Element Colors)
const kWoodColor = Color(0xFF1565C0);    // 목(木) 쨍한 파랑
const kFireColor = Color(0xFFD32F2F);    // 화(火) 쨍한 빨강
const kEarthColor = Color(0xFFF5C800);   // 토(土) 쨍한 노랑
const kMetalColor = Color(0xFFF2EFE8);   // 금(金) 백색
const kWaterColor = Color(0xFF1A1A2E);   // 수(水) 검정/남색

// 단청 강조색 (Dancheong Accent Colors)
const kDancheongBlue = Color(0xFF1565C0);
const kDancheongRed = Color(0xFFD32F2F);
const kDancheongYellow = Color(0xFFF5C800);
const kDancheongGreen = Color(0xFF2E7D32);
const kDancheongWhite = Color(0xFFF2EFE8);

// 하위 호환 별칭 (Legacy aliases)
const kAccentRed = kDancheongRed;
const kSuccessColor = kDancheongGreen;

// ── 코스믹 그라데이션 팔레트 ──
const kCosmicDeep = Color(0xFF060611);      // 깊은 우주 배경
const kCosmicNavy = Color(0xFF0B0B2E);      // 네이비 코스믹
const kCosmicPurple = Color(0xFF1A0A3E);    // 보라 성운
const kCosmicIndigo = Color(0xFF12123A);    // 인디고 우주
const kCosmicViolet = Color(0xFF9B72CF);    // 밝은 보라 악센트
const kCosmicTeal = Color(0xFF1A3A4A);      // 틸 성운

// 글래스 효과용 (뒷배경이 흐릿하게 비쳐야 함)
const kGlassFill = Color(0x0DFFFFFF);       // 5% 흰색 — 매우 투명
const kGlassBorder = Color(0x40FFFFFF);     // 25% 흰색 — 유리 테두리
const kGlassHighlight = Color(0x18FFFFFF);  // 9% 흰색 — 상단 하이라이트
const kGlassFillLight = Color(0x14FFFFFF);  // 8% 흰색 — 약간 더 밝은 글래스

// 골드 그라데이션
const kGoldLight = Color(0xFFFFD94A);       // 밝은 골드
const kGoldDark = Color(0xFFB8940A);        // 어두운 골드
const kGoldGlow = Color(0x40F5C800);        // 골드 글로우
