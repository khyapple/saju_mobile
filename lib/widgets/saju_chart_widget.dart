import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SajuChartWidget extends StatelessWidget {
  final Map<String, dynamic> chartData;

  const SajuChartWidget({super.key, required this.chartData});

  // ── 오행 매핑 ────────────────────────────────────────────
  static const _stemElement = {
    '갑': 'wood', '을': 'wood', '병': 'fire', '정': 'fire',
    '무': 'earth', '기': 'earth', '경': 'metal', '신': 'metal',
    '임': 'water', '계': 'water',
  };
  static const _branchElement = {
    '자': 'water', '축': 'earth', '인': 'wood', '묘': 'wood',
    '진': 'earth', '사': 'fire', '오': 'fire', '미': 'earth',
    '신': 'metal', '유': 'metal', '술': 'earth', '해': 'water',
  };
  static const _stemHanja = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };
  static const _branchHanja = {
    '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰',
    '사': '巳', '오': '午', '미': '未', '신': '申', '유': '酉',
    '술': '戌', '해': '亥',
  };
  static const _elementKorean = {
    'wood': '목', 'fire': '화', 'earth': '토', 'metal': '금', 'water': '수',
  };
  static const _branchMainStem = {
    '자': '계', '축': '기', '인': '갑', '묘': '을',
    '진': '무', '사': '병', '오': '정', '미': '기',
    '신': '경', '유': '신', '술': '무', '해': '임',
  };
  static const _twelveStars = {
    '갑': {'해':'장생','자':'목욕','축':'관대','인':'건록','묘':'제왕','진':'쇠','사':'병','오':'사','미':'묘','신':'절','유':'태','술':'양'},
    '을': {'오':'장생','사':'목욕','진':'관대','묘':'건록','인':'제왕','축':'쇠','자':'병','해':'사','술':'묘','유':'절','신':'태','미':'양'},
    '병': {'인':'장생','묘':'목욕','진':'관대','사':'건록','오':'제왕','미':'쇠','신':'병','유':'사','술':'묘','해':'절','자':'태','축':'양'},
    '정': {'유':'장생','신':'목욕','미':'관대','오':'건록','사':'제왕','진':'쇠','묘':'병','인':'사','축':'묘','자':'절','해':'태','술':'양'},
    '무': {'인':'장생','묘':'목욕','진':'관대','사':'건록','오':'제왕','미':'쇠','신':'병','유':'사','술':'묘','해':'절','자':'태','축':'양'},
    '기': {'유':'장생','신':'목욕','미':'관대','오':'건록','사':'제왕','진':'쇠','묘':'병','인':'사','축':'묘','자':'절','해':'태','술':'양'},
    '경': {'사':'장생','오':'목욕','미':'관대','신':'건록','유':'제왕','술':'쇠','해':'병','자':'사','축':'묘','인':'절','묘':'태','진':'양'},
    '신': {'자':'장생','해':'목욕','술':'관대','유':'건록','신':'제왕','미':'쇠','오':'병','사':'사','진':'묘','묘':'절','인':'태','축':'양'},
    '임': {'신':'장생','유':'목욕','술':'관대','해':'건록','자':'제왕','축':'쇠','인':'병','묘':'사','진':'묘','사':'절','오':'태','미':'양'},
    '계': {'묘':'장생','인':'목욕','축':'관대','자':'건록','해':'제왕','술':'쇠','유':'병','신':'사','미':'묘','오':'절','사':'태','진':'양'},
  };

  // ── 뜻 사전 ──────────────────────────────────────────────
  static const _meanings = <String, Map<String, String>>{
    // 천간
    '갑': {'title': '갑 (甲)', 'sub': '나무 기운 · 강한 남성성', 'desc': '큰 나무처럼 곧고 강하게 위로 뻗어나가는 성질이에요. 새로운 걸 시작하고 앞장서는 걸 좋아하고, 자존심이 강하고 독립적이에요. 리더 기질이 있지만 고집도 센 편이에요.'},
    '을': {'title': '을 (乙)', 'sub': '나무 기운 · 부드러운 여성성', 'desc': '작은 풀이나 덩굴처럼 유연하게 환경에 적응하는 성질이에요. 바람에 휘어도 꺾이지 않는 강한 생명력을 가지고 있어요. 섬세하고 예술적 감각이 뛰어나며 끈기가 있어요.'},
    '병간': {'title': '병 (丙)', 'sub': '불 기운 · 강한 남성성', 'desc': '태양처럼 밝고 뜨거운 성질이에요. 활발하고 명랑하며 주변 사람들을 환하게 밝혀줘요. 표현력이 강하고 인기가 많은 편이에요.'},
    '정': {'title': '정 (丁)', 'sub': '불 기운 · 부드러운 여성성', 'desc': '촛불처럼 은은하고 따뜻한 성질이에요. 조용하지만 날카로운 통찰력이 있고 감수성이 풍부해요. 겉은 차분해 보여도 속에 깊은 생각과 예술성을 품고 있어요.'},
    '무': {'title': '무 (戊)', 'sub': '흙 기운 · 강한 남성성', 'desc': '큰 산처럼 묵직하고 안정적인 성질이에요. 무엇이든 품어주는 포용력이 있고 믿음직해요. 한번 맡은 일은 끝까지 해내는 책임감이 강한 사람이에요.'},
    '기': {'title': '기 (己)', 'sub': '흙 기운 · 부드러운 여성성', 'desc': '비옥한 들판처럼 만물을 길러주는 따뜻한 성질이에요. 세심하고 현실적이며 실속을 챙길 줄 알아요. 배려심이 깊고 주변을 잘 돌봐줘요.'},
    '경': {'title': '경 (庚)', 'sub': '쇠 기운 · 강한 남성성', 'desc': '단단한 금속처럼 날카롭고 강인한 성질이에요. 정의감이 강하고 원칙을 중시하며 타협을 잘 안 해요. 결단력이 뛰어나고 한번 결심하면 밀어붙이는 추진력이 있어요.'},
    '신간': {'title': '신 (辛)', 'sub': '쇠 기운 · 부드러운 여성성', 'desc': '정제된 보석처럼 빛나는 성질이에요. 미적 감각이 뛰어나고 완벽주의 성향이 있어요. 말이 날카롭고 직관이 예리하며 언변이 좋아요.'},
    '임': {'title': '임 (壬)', 'sub': '물 기운 · 강한 남성성', 'desc': '큰 강처럼 깊고 넓게 흐르는 성질이에요. 상황 파악이 빠르고 다재다능해요. 포용력이 넘치며 임기응변에 강해요.'},
    '계': {'title': '계 (癸)', 'sub': '물 기운 · 부드러운 여성성', 'desc': '빗물이나 안개처럼 스며드는 섬세한 성질이에요. 감수성이 풍부하고 직감이 뛰어나요. 내면세계가 깊고 창의적이며 신비로운 분위기를 가지고 있어요.'},
    // 지지
    '자': {'title': '자 (子)', 'sub': '🐭 쥐띠 · 물 기운 · 한겨울', 'desc': '겉은 고요해 보이지만 안에 넘치는 에너지를 품고 있어요. 총명하고 재치가 넘치며 탐구하는 걸 좋아해요. 밤 11시~새벽 1시 사이에 태어났다면 이 기운을 강하게 받아요.'},
    '축': {'title': '축 (丑)', 'sub': '🐮 소띠 · 흙 기운 · 겨울 끝', 'desc': '묵묵히 자기 길을 걷는 성실한 기운이에요. 빠르진 않아도 착실하게 쌓아가는 스타일이에요. 끈기 있고 현실적이며 한번 마음먹으면 포기를 잘 안 해요.'},
    '인': {'title': '인 (寅)', 'sub': '🐯 호랑이띠 · 나무 기운 · 초봄', 'desc': '호랑이처럼 용맹하고 활동적인 기운이에요. 새로운 걸 시작하는 에너지가 넘치고 카리스마가 강해요. 리더십이 있고 도전을 즐기는 타입이에요.'},
    '묘지': {'title': '묘 (卯)', 'sub': '🐰 토끼띠 · 나무 기운 · 봄 절정', 'desc': '꽃이 활짝 피어나는 것처럼 부드럽고 생기 넘치는 기운이에요. 유연하고 친화력이 뛰어나며 사람들과 잘 어울려요. 예술적 감각도 좋아요.'},
    '진': {'title': '진 (辰)', 'sub': '🐲 용띠 · 흙 기운 · 늦봄', 'desc': '신비롭고 역동적인 기운이에요. 꿈이 크고 창의적이며 독특한 개성을 가지고 있어요. 매력적이고 변화를 즐기는 편이에요.'},
    '사지': {'title': '사 (巳)', 'sub': '🐍 뱀띠 · 불 기운 · 초여름', 'desc': '뱀처럼 신중하고 지혜로운 기운이에요. 상황을 꼼꼼히 살피고 판단이 냉철해요. 인내심이 강하고 재물을 모으는 능력이 있어요.'},
    '오': {'title': '오 (午)', 'sub': '🐴 말띠 · 불 기운 · 여름 절정', 'desc': '말처럼 자유롭고 열정적인 기운이에요. 밝고 활달하며 표현력이 넘쳐요. 자유를 사랑하고 직선적인 성격이에요.'},
    '미': {'title': '미 (未)', 'sub': '🐑 양띠 · 흙 기운 · 늦여름', 'desc': '온화하고 풍요로운 기운이에요. 감수성이 풍부하고 배려심이 깊어요. 인간관계를 소중히 여기고 예술적 감각이 있어요.'},
    '신지': {'title': '신 (申)', 'sub': '🐵 원숭이띠 · 쇠 기운 · 초가을', 'desc': '원숭이처럼 재치 있고 영리한 기운이에요. 상황 파악이 빠르고 다양한 분야에 관심이 많아요. 활동적이고 적응력이 뛰어나요.'},
    '유': {'title': '유 (酉)', 'sub': '🐔 닭띠 · 쇠 기운 · 가을 절정', 'desc': '날카롭고 완성도를 추구하는 기운이에요. 미적 감각이 뛰어나고 섬세하며 완벽주의 성향이 있어요. 분석적이고 현실적인 편이에요.'},
    '술': {'title': '술 (戌)', 'sub': '🐶 개띠 · 흙 기운 · 늦가을', 'desc': '개처럼 충직하고 든든한 기운이에요. 의리가 강하고 한번 믿으면 끝까지 믿어줘요. 책임감이 강하고 헌신적이에요.'},
    '해': {'title': '해 (亥)', 'sub': '🐷 돼지띠 · 물 기운 · 초겨울', 'desc': '여유롭고 복이 넘치는 기운이에요. 순박하고 낙천적이며 사람들에게 인기가 많아요. 인복이 있고 인간미가 넘쳐요.'},
    // 십성
    '비견': {'title': '비견 (比肩)', 'sub': '나와 성질이 같은 기운', 'desc': '나(일주)와 오행도 같고 강약도 같은 기운이에요. 독립심과 자존심이 강하고 내 방식대로 하려는 성향이 있어요. 경쟁심도 세지만 그만큼 자립적으로 살아가는 힘이 커요.'},
    '겁재': {'title': '겁재 (劫財)', 'sub': '나와 비슷하지만 성질이 반대인 기운', 'desc': '오행은 나와 같지만 강약이 반대인 기운이에요. 행동력과 승부욕이 강하고 결단이 빨라요. 때로는 충동적이지만 강한 의지로 어려움을 뚫고 나가는 힘이 있어요.'},
    '식신': {'title': '식신 (食神)', 'sub': '내가 에너지를 주는 기운 · 먹복', 'desc': '내가 힘을 불어넣어 키워주는 기운이에요. 표현력과 창의력이 뛰어나고 여유롭게 삶을 즐길 줄 알아요. 먹고 사는 복, 예술적 재능과 연결되는 좋은 기운이에요.'},
    '상관': {'title': '상관 (傷官)', 'sub': '내가 에너지를 주는 기운 · 재능', 'desc': '식신처럼 내가 키워주는 기운이지만 더 강하고 자유분방해요. 재능과 언변이 뛰어나고 창의적이에요. 틀에 갇히기 싫어하고 규칙이나 권위에 반발하는 기질이 있어요.'},
    '편재': {'title': '편재 (偏財)', 'sub': '내가 통제하는 기운 · 활동적 재물', 'desc': '내가 상대를 다스리는 관계예요. 활발하게 움직이며 돈을 벌고 쓰는 기운이에요. 사업 감각이 있고 투자를 즐기며 씀씀이가 크고 인간관계가 넓어요.'},
    '정재': {'title': '정재 (正財)', 'sub': '내가 통제하는 기운 · 안정적 재물', 'desc': '편재처럼 내가 다스리는 기운인데 더 안정적이에요. 꾸준한 수입과 성실한 재물 관리를 뜻해요. 저축을 잘하고 현실적이며 책임감이 강해요.'},
    '편관': {'title': '편관 (偏官)', 'sub': '나를 압박하는 기운 · 극복과 도전', 'desc': '상대가 나를 강하게 누르는 기운이에요. 스트레스나 압박을 의미하기도 하지만 그걸 이겨낼 때 강해지는 에너지예요. 강한 의지와 추진력을 키워주고 군인·경찰 같은 강직한 직업과 잘 맞아요.'},
    '정관': {'title': '정관 (正官)', 'sub': '나를 다스리는 기운 · 명예와 질서', 'desc': '상대가 나를 부드럽게 이끌어주는 기운이에요. 규칙과 도덕을 중시하고 사회에서 인정받는 걸 소중히 여겨요. 품위 있고 신뢰받는 스타일이에요.'},
    '편인': {'title': '편인 (偏印)', 'sub': '나를 키워주는 기운 · 직관과 개성', 'desc': '상대가 나를 도와주는 기운인데 독특한 방식이에요. 직관이 강하고 아이디어가 독창적이에요. 신비로운 분야나 예술에 관심이 많고 가끔 변덕스러운 면도 있어요.'},
    '정인': {'title': '정인 (正印)', 'sub': '나를 키워주는 기운 · 지식과 보호', 'desc': '상대가 나를 편안하고 안정적으로 키워주는 기운이에요. 학문을 좋아하고 인격이 높으며 주변의 신뢰를 받아요. 어머니처럼 따뜻하게 보살펴주는 에너지예요.'},
    // 12운성
    '장생': {'title': '장생 (長生)', 'sub': '12운성 1단계 · 태어남', 'desc': '아기가 세상에 태어난 것처럼 새로운 시작의 에너지예요. 순수하고 밝으며 가능성이 넘쳐요. 활기차고 희망적인 기운이에요.'},
    '목욕': {'title': '목욕 (沐浴)', 'sub': '12운성 2단계 · 감수성과 자유', 'desc': '태어난 아기를 씻기는 단계예요. 감수성이 풍부하고 감정이 예민해요. 이성에 관심이 많고 자유로운 기질이 있어요. 예술적 감각이 뛰어난 편이에요.'},
    '관대': {'title': '관대 (冠帶)', 'sub': '12운성 3단계 · 성장과 준비', 'desc': '청년이 되어 사회에 나갈 준비를 하는 단계예요. 열심히 배우고 실력을 키워가는 시기예요. 야망이 있고 성취욕이 강해요.'},
    '건록': {'title': '건록 (建祿)', 'sub': '12운성 4단계 · 자립과 활약', 'desc': '독립해서 본격적으로 일하는 단계예요. 자립심이 강하고 실력이 뛰어나요. 스스로 노력해서 성공을 만들어내는 타입이에요.'},
    '제왕': {'title': '제왕 (帝旺)', 'sub': '12운성 5단계 · 전성기', 'desc': '능력과 힘이 최고조에 달한 전성기예요. 무엇이든 이룰 수 있는 에너지가 넘쳐요. 리더십이 강하고 패기가 있어요.'},
    '쇠': {'title': '쇠 (衰)', 'sub': '12운성 6단계 · 전성기 이후', 'desc': '전성기가 지나고 서서히 내려오는 단계예요. 젊은 혈기는 줄지만 경험에서 나오는 지혜가 풍부해요. 원숙함으로 주변을 이끌어가요.'},
    '병운': {'title': '병 (病)', 'sub': '12운성 7단계 · 기운이 약해짐', 'desc': '기운이 조금씩 빠지는 단계예요. 섬세하고 감수성이 깊어요. 건강을 챙기는 게 중요하고 의료나 예술 쪽과 인연이 깊어요.'},
    '사운': {'title': '사 (死)', 'sub': '12운성 8단계 · 기운이 다함', 'desc': '에너지가 밖으로 드러나기보다 내면으로 향하는 단계예요. 깊은 통찰력과 정신적 풍요로움이 있어요. 철학이나 연구 분야에서 빛을 발해요.'},
    '묘운': {'title': '묘 (墓)', 'sub': '12운성 9단계 · 저장과 축적', 'desc': '씨앗이 땅속에 묻혀 에너지를 저장하는 단계예요. 눈에 띄지 않지만 안에 힘을 쌓아가는 시기예요. 재물을 모으는 능력이 뛰어나요.'},
    '절': {'title': '절 (絶)', 'sub': '12운성 10단계 · 완전한 전환', 'desc': '완전히 끊어지고 새로 시작하는 전환점이에요. 이동이나 변화가 많고 새로운 인연이 생기는 시기예요. 변화를 두려워하지 않는 신비로운 기운이에요.'},
    '태': {'title': '태 (胎)', 'sub': '12운성 11단계 · 잉태', 'desc': '엄마 뱃속에 새 생명이 들어선 것 같은 단계예요. 아직 세상에 드러나진 않았지만 무한한 가능성을 품고 있어요. 상상력이 풍부해요.'},
    '양': {'title': '양 (養)', 'sub': '12운성 12단계 · 양육과 준비', 'desc': '태어날 준비를 하며 보살핌을 받는 단계예요. 따뜻하게 길러지며 성장하는 에너지예요. 감수성이 풍부하고 예술성이 있어요.'},
    // 행·열 라벨
    '천간': {'title': '천간 (天干)', 'sub': '사주 위쪽 글자 · 10가지', 'desc': '갑·을·병·정·무·기·경·신·임·계, 이렇게 10개 글자로 이루어져 있어요. 나무·불·흙·쇠·물 다섯 가지 기운을 각각 강한 것과 부드러운 것으로 나눈 거예요. 사주표에서 위쪽에 있는 글자가 천간이고, 내가 겉으로 드러내는 성격이나 재능을 보여줍니다.'},
    '천간십성': {'title': '천간 십성 (天干 十星)', 'sub': '나와의 관계를 나타내는 이름표', 'desc': '일주(나)를 기준으로 다른 천간들이 나와 어떤 관계인지 이름을 붙인 거예요. 예를 들어 나와 성질이 같으면 비견, 내가 도와주는 기운이면 식신, 나를 눌러주는 기운이면 편관 이런 식이에요. 각 관계가 재물·직업·인간관계 등 삶의 어느 부분과 연결되는지 알려줍니다.'},
    '지지': {'title': '지지 (地支)', 'sub': '사주 아래쪽 글자 · 12가지', 'desc': '자·축·인·묘·진·사·오·미·신·유·술·해, 이렇게 12개 글자예요. 12달·12방위·12띠 동물이 여기서 나옵니다. 사주표에서 아래쪽에 있는 글자가 지지이고, 내가 살아가는 환경과 운의 흐름을 보여줍니다.'},
    '지지십성': {'title': '지지 십성 (地支 十星)', 'sub': '지지의 숨겨진 성질로 본 관계', 'desc': '지지 글자 안에는 대표 천간이 하나씩 숨어 있어요. 그 대표 천간과 나(일주) 사이의 관계를 이름 붙인 것이 지지십성입니다. 땅의 기운이 실제 내 삶에 어떤 영향을 미치는지 보여줍니다.'},
    '지장간': {'title': '지장간 (支藏干)', 'sub': '지지 글자 안에 숨어 있는 천간들', 'desc': '지지 글자 하나 안에는 사실 여러 개의 천간이 들어 있어요. 마치 양파 껍질처럼 겹겹이 쌓여 있는 거예요. 운이 흘러가면서 이 안에 숨은 글자들이 하나씩 활성화되며 인생의 세세한 변화를 만들어냅니다.'},
    '12운성': {'title': '12운성 (十二運星)', 'sub': '내 기운이 얼마나 강한지 보여주는 12단계', 'desc': '장생(태어남) → 목욕 → 관대 → 건록 → 제왕(전성기) → 쇠 → 병 → 사 → 묘 → 절 → 태 → 양 순서로 순환해요. 사람이 태어나고 자라고 늙는 것처럼, 내 기운도 각 지지에서 이 12단계 중 어디에 해당하는지 알려줍니다.'},
    '시주': {'title': '시주 (時柱)', 'sub': '태어난 시간의 기둥', 'desc': '태어난 시간을 나타내는 두 글자예요. 하루를 2시간씩 12구간으로 나눈 것 중 어디에 해당하는지 알 수 있어요. 자식복이나 노년의 삶, 내 주변 사람들과의 관계를 주로 나타냅니다.'},
    '일주': {'title': '일주 (日柱)', 'sub': '태어난 날의 기둥 · 나 자신', 'desc': '사주에서 가장 중요한 기둥이에요. 위쪽 글자(천간)가 바로 \'나\'를 뜻하고, 이걸 기준으로 모든 관계와 성격을 읽습니다. 나의 타고난 성격, 기질, 배우자와의 인연도 여기서 봅니다.'},
    '월주': {'title': '월주 (月柱)', 'sub': '태어난 달의 기둥', 'desc': '태어난 달을 나타내는 두 글자예요. 사주 네 기둥 중에서 영향력이 가장 강한 편이에요. 부모·형제와의 관계, 직업, 사회생활이 잘 드러나며 20~40대 인생의 흐름을 주로 보여줍니다.'},
    '연주': {'title': '연주 (年柱)', 'sub': '태어난 해의 기둥', 'desc': '태어난 해를 나타내는 두 글자예요. 띠가 여기서 나옵니다. 어린 시절 환경이나 집안 분위기, 조상과의 인연을 보여주며 인생 초반의 흐름을 나타냅니다.'},
  };

  // ── 뜻 키 헬퍼 ───────────────────────────────────────────
  static String _stemKey(String c) {
    if (c == '신') return '신간';
    if (c == '병') return '병간';
    return c;
  }
  static String _branchKey(String c) {
    if (c == '신') return '신지';
    if (c == '사') return '사지';
    if (c == '묘') return '묘지';
    return c;
  }
  static String _starKey(String c) {
    if (c == '병') return '병운';
    if (c == '사') return '사운';
    if (c == '묘') return '묘운';
    return c;
  }

  // ── 십성 계산 ─────────────────────────────────────────────
  static String _tenGod(String dayMaster, String target) {
    const el = {
      '갑': 'wood', '을': 'wood', '병': 'fire', '정': 'fire',
      '무': 'earth', '기': 'earth', '경': 'metal', '신': 'metal',
      '임': 'water', '계': 'water',
    };
    const yang = {'갑', '병', '무', '경', '임'};
    const gen  = {'wood':'fire','fire':'earth','earth':'metal','metal':'water','water':'wood'};
    const ctrl = {'wood':'earth','earth':'water','water':'fire','fire':'metal','metal':'wood'};
    final dmEl = el[dayMaster]; final tEl = el[target];
    if (dmEl == null || tEl == null) return '';
    final same = yang.contains(dayMaster) == yang.contains(target);
    if (dmEl == tEl)       return same ? '비견' : '겁재';
    if (gen[dmEl] == tEl)  return same ? '식신' : '상관';
    if (ctrl[dmEl] == tEl) return same ? '편재' : '정재';
    if (ctrl[tEl] == dmEl) return same ? '편관' : '정관';
    if (gen[tEl] == dmEl)  return same ? '편인' : '정인';
    return '';
  }

  static Color _elementColor(String? element) {
    switch (element) {
      case 'wood':  return kWoodColor;
      case 'fire':  return kFireColor;
      case 'earth': return kEarthColor;
      case 'metal': return kMetalColor;
      case 'water': return kWaterColor;
      default:      return kDark;
    }
  }

  // ── 뜻 바텀시트 ───────────────────────────────────────────
  static void _showMeaning(BuildContext context, String key) {
    final info = _meanings[key];
    if (info == null || key.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: kCosmicNavy.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: kGlassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(info['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kGold)),
                const SizedBox(height: 4),
                Text(info['sub'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.white54)),
                const SizedBox(height: 16),
                Container(height: 0.5, color: kGlassBorder),
                const SizedBox(height: 16),
                Text(info['desc'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.7)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 빌드 ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final year  = chartData['yearPillar']  as Map<String, dynamic>?;
    final month = chartData['monthPillar'] as Map<String, dynamic>?;
    final day   = chartData['dayPillar']   as Map<String, dynamic>?;
    final hour  = chartData['hourPillar']  as Map<String, dynamic>?;

    if (year == null && month == null && day == null) {
      return const Center(child: Text('차트 데이터 없음', style: TextStyle(color: kTextMuted)));
    }

    final pillars = [hour, day, month, year];
    final labels  = ['시주', '일주', '월주', '연주'];
    final dayMaster = _stemChar(day);
    const lw = 38.0;

    Widget rowLabel(String text, {String? key}) {
      final lookupKey = key ?? text.replaceAll('\n', '');
      final tappable = _meanings.containsKey(lookupKey);
      return GestureDetector(
        onTap: tappable ? () => _showMeaning(context, lookupKey) : null,
        child: SizedBox(
          width: lw,
          child: Center(
            child: Text(text, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: tappable ? Colors.white70 : Colors.white54, height: 1.3)),
          ),
        ),
      );
    }

    Widget textCell(String text, {String? key}) {
      final lookupKey = key ?? text;
      final tappable = lookupKey.isNotEmpty && _meanings.containsKey(lookupKey);
      return Expanded(
        child: GestureDetector(
          onTap: tappable ? () => _showMeaning(context, lookupKey) : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: tappable ? const Color(0x14FFFFFF) : const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tappable ? kGlassBorder : kGlassBorder.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(text,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500,
                  color: tappable ? Colors.white70 : Colors.white38,
                )),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGlassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGlassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(children: [
            SizedBox(width: lw),
            ...List.generate(4, (i) => Expanded(
              child: GestureDetector(
                onTap: () => _showMeaning(context, labels[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Text(labels[i],
                      style: const TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 4),

          // 천간
          Row(children: [
            rowLabel('천간'),
            ...List.generate(4, (i) {
              final stem = _stemChar(pillars[i]);
              return Expanded(child: GestureDetector(
                onTap: stem.isNotEmpty ? () => _showMeaning(context, _stemKey(stem)) : null,
                child: _pillarCell(stem, _stemElement[stem], isStem: true),
              ));
            }),
          ]),
          const SizedBox(height: 4),

          // 천간 십성
          Row(children: [
            rowLabel('천간\n십성', key: '천간십성'),
            ...List.generate(4, (i) {
              final stem = _stemChar(pillars[i]);
              final god = dayMaster.isNotEmpty && stem.isNotEmpty ? _tenGod(dayMaster, stem) : '';
              return textCell(god);
            }),
          ]),
          const SizedBox(height: 4),

          // 지지
          Row(children: [
            rowLabel('지지'),
            ...List.generate(4, (i) {
              final branch = _branchChar(pillars[i]);
              return Expanded(child: GestureDetector(
                onTap: branch.isNotEmpty ? () => _showMeaning(context, _branchKey(branch)) : null,
                child: _pillarCell(branch, _branchElement[branch], isStem: false),
              ));
            }),
          ]),
          const SizedBox(height: 4),

          // 지지 십성
          Row(children: [
            rowLabel('지지\n십성', key: '지지십성'),
            ...List.generate(4, (i) {
              final branch = _branchChar(pillars[i]);
              final main = _branchMainStem[branch] ?? '';
              final god = dayMaster.isNotEmpty && main.isNotEmpty ? _tenGod(dayMaster, main) : '';
              return textCell(god);
            }),
          ]),
          const SizedBox(height: 4),

          // 지장간
          Row(children: [
            rowLabel('지장간'),
            ...List.generate(4, (i) {
              final hidden = _hiddenStems(pillars[i]);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kGlassBorder),
                  ),
                  child: Center(
                    child: hidden.isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: hidden.map((h) => GestureDetector(
                              onTap: () => _showMeaning(context, _stemKey(h)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Text(h,
                                  style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              ),
                            )).toList(),
                          ),
                  ),
                ),
              );
            }),
          ]),
          const SizedBox(height: 4),

          // 12운성
          Row(children: [
            rowLabel('12\n운성', key: '12운성'),
            ...List.generate(4, (i) {
              final branch = _branchChar(pillars[i]);
              final star = (dayMaster.isNotEmpty && branch.isNotEmpty)
                  ? (_twelveStars[dayMaster]?[branch] ?? '')
                  : '';
              return textCell(star, key: _starKey(star));
            }),
          ]),
        ],
      ),
    );
  }

  String _stemChar(Map<String, dynamic>? pillar) {
    final stem = pillar?['stem'] as Map<String, dynamic>?;
    return stem?['char'] as String? ?? '';
  }

  String _branchChar(Map<String, dynamic>? pillar) {
    final branch = pillar?['branch'] as Map<String, dynamic>?;
    return branch?['char'] as String? ?? '';
  }

  List<String> _hiddenStems(Map<String, dynamic>? pillar) {
    final branch = pillar?['branch'] as Map<String, dynamic>?;
    final list = branch?['hiddenStems'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((h) => (h as Map<String, dynamic>)['stem'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Widget _pillarCell(String text, String? element, {required bool isStem}) {
    final color = _elementColor(element);
    final hanja = isStem ? _stemHanja[text] : _branchHanja[text];
    final elementName = element != null ? _elementKorean[element] : null;
    const shadows = [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))];

    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ColoredBox(
          color: color.withOpacity(element == 'water' ? 0.45 : 0.28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
              children: [
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.02), color.withOpacity(0.15)],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                )),
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      stops: const [0.0, 0.38, 0.42, 1.0],
                      colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02), Colors.transparent, Colors.transparent],
                    ),
                  ),
                )),
                Positioned.fill(child: CustomPaint(painter: _GlassEdgePainter())),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, shadows: shadows)),
                      if (hanja != null) ...[
                        const SizedBox(height: 1),
                        Text(hanja, style: const TextStyle(fontSize: 11, color: Colors.white70, shadows: shadows)),
                      ],
                    ],
                  ),
                ),
                if (elementName != null)
                  Positioned(right: 4, bottom: 4,
                    child: Text(elementName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white60, shadows: shadows))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  static const double _r = 6.0;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0.5, size.height), const Offset(0.5, _r),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, 1, size.height)));
    canvas.drawPath(
      Path()..moveTo(0.5, _r)..arcToPoint(const Offset(_r, 0.5), radius: const Radius.circular(_r), clockwise: true),
      Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawLine(const Offset(_r, 0.5), Offset(size.width, 0.5),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0
        ..shader = LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 1)));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
