import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Song { 
  final String id;
  final String title;
  final String artist;
  final String language;
  final String deity;
  final String lyrics;
  final Color cardColor;
  final IconData icon;
  final String audioUrl;

  const Song({
    required this.id, required this.title, required this.artist,
    required this.language, required this.deity,
    required this.lyrics, required this.cardColor, required this.icon,
    required this.audioUrl,
  });
}

final List<Song> _allSongs = [
  const Song(
    id: 's1', title: 'Suprabhatam', artist: 'M.S. Subbulakshmi',
    language: 'Sanskrit', deity: 'Vishnu',
    cardColor: Color(0xFF1565C0), icon: Icons.temple_hindu,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/VenkatesaSuprabhatam.mp3',
    lyrics: 'Kausalya supraja Rama\nPoorva sandhya pravartate\nUttishtha narasardoola\nKartavyam daivam ahnikam\n\nUttishthottishtha Govinda\nUttishtha Garuda dhwaja\nUttishtha Kamalakantha\nTrilokyam mangalam kuru',
  ),
  const Song(
    id: 's2', title: 'Vinayagar Agaval', artist: 'Avvaiyar',
    language: 'Tamil', deity: 'Ganesha',
    cardColor: Color(0xFFE65100), icon: Icons.self_improvement,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/Ganesha%20Stotram.mp3',
    lyrics: 'Ambigai magan adiyai potri\nAruludan kanagarathinam potri\nSeeraar kazhale potri potri\nNan manam kavar thiruvadikal potri\n\nOm Gam Ganapataye namaha\nVighna nasaya namaha',
  ),
  const Song(
    id: 's3', title: 'Thirupugazh', artist: 'Arunagirinathar',
    language: 'Tamil', deity: 'Murugan',
    cardColor: Color(0xFF880E4F), icon: Icons.music_note,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/Jagatini.mp3',
    lyrics: 'Kaithal saevadi potri\nKarunaikkadal potri\nMurugarasane potri\nVel vel muruga vel\n\nSakti vel muruga vel\nKandha vel muruga vel\nAaru mugan potri potri',
  ),
  const Song(
    id: 's4', title: 'Hanuman Chalisa', artist: 'Anup Jalota',
    language: 'Hindi', deity: 'Hanuman',
    cardColor: Color(0xFF2E7D32), icon: Icons.waves,
    audioUrl: 'https://archive.org/download/HanumanSongsListenOnTuesday/Hanuman-Chalisa-AnupJalota.mp3',
    lyrics: 'Shri Guru Charan Saroj raj\nNij man mukur sudhari\nBarnau Raghubar Bimal Yash\nJo dayaku Phal chari\n\nJai Hanuman gyan gun sagar\nJai Kapis tihun lok ujagar',
  ),
  const Song(
    id: 's5', title: 'Venkatesa Suprabhatam', artist: 'SPB',
    language: 'Sanskrit', deity: 'Vishnu',
    cardColor: Color(0xFF4A148C), icon: Icons.temple_hindu,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/VenkatesaSuprabhatam.mp3',
    lyrics: 'Kamalakucha choochuka kunkumatho\nNiyatharunitha thata niyanthritha\nBhavatu thava manthasmitha bhaavitha\nMama manaasa manaasa ramathaam\n\nOm namo venkatesaya\nGovindaya namo namaha',
  ),
  const Song(
    id: 's6', title: 'Lalitha Sahasranamam', artist: 'Traditional',
    language: 'Sanskrit', deity: 'Devi',
    cardColor: Color(0xFFAD1457), icon: Icons.auto_awesome,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/Kaliamma',
    lyrics: 'Om aim hrim shrim\nShri Lalita tripura sundari\nParabhattarika namaha\n\nSri Mata Sri Maharajni\nShrimat Simhasaneshvari\nChidagni Kunda Sambhoota\nDeva Karya Samudhyata',
  ),
  const Song(
    id: 's7', title: 'Om Namah Shivaya', artist: 'Traditional',
    language: 'Sanskrit', deity: 'Shiva',
    cardColor: Color(0xFF37474F), icon: Icons.brightness_3,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/Lord%20Shiva%20Rudra%20Mantra%20-%20Om%20Sivoham%20Rudra%20Naamam%20Bajeham.mp3',
    lyrics: 'Om namah shivaya\nOm namah shivaya\nShiva shankara mahadeva\nOm namah shivaya\n\nHara hara mahadeva\nShambho shankara\nNamami shankaram sharadam\nPada pankajam',
  ),
  const Song(
    id: 's8', title: 'Durga Chalisa', artist: 'Traditional',
    language: 'Sanskrit', deity: 'Devi',
    cardColor: Color(0xFFBF360C), icon: Icons.favorite,
    audioUrl: 'https://archive.org/download/hemanth_gundubogula/Durga%20Chalisa.mp3',
    lyrics: 'Thiripura sundariye\nThillai ambala aadiye\nThiruvadi potri potri\nAbirami devi potri\n\nKadampavana vaasini\nKarunai maamani\nKamala malai potri\nKalyani potri',
  ),
  const Song(
    id: 's9', title: 'Gayatri Mantra', artist: 'Traditional',
    language: 'Sanskrit', deity: 'Surya',
    cardColor: Color(0xFFF57F17), icon: Icons.wb_sunny,
    audioUrl: 'https://archive.org/download/HinduGodSongs/Gayatri%20Mantra.mp3',
    lyrics: 'Om Bhur Bhuvah Svah\nTat Savitur Varenyam\nBhargo Devasya Dheemahi\nDhiyo Yo Nah Prachodayat\n\nOm Om Om\nGayatri mantra mahima\nAaditya hridayam punyam\nSarva shatru vinashanam',
  ),
  const Song(
    id: 's10', title: 'Hanuman Chalisa', artist: 'M.S. Rama Rao',
    language: 'Sanskrit', deity: 'Hanuman',
    cardColor: Color(0xFF1A237E), icon: Icons.star,
    audioUrl: 'https://archive.org/download/HanumanSongsListenOnTuesday/Hanuman-Chalisa-MSRR.mp3',
    lyrics: 'Shuklambaradharam Vishnum\nShasivarna Chaturbhujam\nPrasanna Vadanam Dhyayet\nSarva Vighna Upashantaye\n\nVishwam Vishnur Vashatkaro\nBhuta Bhavya Bhavat Prabhuh',
  ),
];
class BakthiPadalPage extends StatefulWidget {
  const BakthiPadalPage({super.key});
  @override
  State<BakthiPadalPage> createState() => _BakthiPadalPageState();
}

class _BakthiPadalPageState extends State<BakthiPadalPage>
    with SingleTickerProviderStateMixin {

  // ── Light Saffron + White Theme ──
  static const Color _primary   = Color(0xFFFF9933);
  static const Color _bg        = Color(0xFFFFF8F0); // warm white
  static const Color _cardBg    = Colors.white;
  static const Color _textDark  = Color(0xFF3E1F00);
  static const Color _textGrey  = Color(0xFF9E7A50);
  static const Color _accent    = Color(0xFFFFE0B2); // light saffron

  String _selectedLanguage = 'All';
  String _selectedDeity    = 'All';
  Song?  _currentSong;
  bool   _isPlaying = false;
  double _progress  = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final AudioPlayer _player = AudioPlayer();
  late AnimationController _rotationController;

  final List<String> _languages = ['All', 'Tamil', 'Sanskrit', 'Hindi'];
  final List<String> _deities   = ['All', 'Vishnu', 'Shiva', 'Murugan', 'Ganesha', 'Devi', 'Hanuman', 'Surya'];

  List<Song> get _filtered => _allSongs.where((s) {
    final l = _selectedLanguage == 'All' || s.language == _selectedLanguage;
    final d = _selectedDeity   == 'All' || s.deity    == _selectedDeity;
    return l && d;
  }).toList();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))..repeat();
    _rotationController.stop();

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
      state == PlayerState.playing
          ? _rotationController.repeat()
          : _rotationController.stop();
    });

    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() {
        _position = p;
        _progress = _duration.inMilliseconds > 0
            ? p.inMilliseconds / _duration.inMilliseconds
            : 0.0;
      });
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() { _isPlaying = false; _progress = 0.0; _position = Duration.zero; });
      _rotationController.stop();
      final idx = _allSongs.indexWhere((s) => s.id == _currentSong?.id);
      if (idx >= 0 && idx < _allSongs.length - 1) _playSong(_allSongs[idx + 1]);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _playSong(Song song) async {
    setState(() { _currentSong = song; _progress = 0.0; _position = Duration.zero; });
    await _player.stop();
    await _player.play(UrlSource(song.audioUrl));
  }

  Future<void> _togglePlay() async {
    _isPlaying ? await _player.pause() : await _player.resume();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openLyrics(Song song) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(width: 50, height: 50,
                    decoration: BoxDecoration(color: song.cardColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(song.icon, color: Colors.white, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(song.title, style: const TextStyle(color: _textDark, fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(song.artist, style: const TextStyle(color: _textGrey, fontSize: 13)),
                ])),
              ]),
            ),
            const Divider(color: _accent, height: 24),
            Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
              const Text('Lyrics', style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              Text(song.lyrics, style: const TextStyle(color: _textDark, fontSize: 16, height: 2.0)),
              const SizedBox(height: 40),
            ])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.music_note, color: Colors.white),
          SizedBox(width: 8),
          Text('Bakthi Padal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            color: _primary,
            child: Column(children: [
              // Language filter
              SizedBox(height: 44, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _languages.length,
                itemBuilder: (_, i) {
                  final sel = _selectedLanguage == _languages[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLanguage = _languages[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_languages[i], style: TextStyle(
                          color: sel ? _primary : Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              )),
              // Deity filter
              SizedBox(height: 44, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _deities.length,
                itemBuilder: (_, i) {
                  final sel = _selectedDeity == _deities[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDeity = _deities[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.7))),
                      child: Text(_deities[i], style: TextStyle(
                          color: sel ? _primary : Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              )),
            ]),
          ),
        ),
      ),
      body: Column(children: [
        // Song list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, _currentSong != null ? 150 : 16),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final song = _filtered[i];
              final isPlaying = _currentSong?.id == song.id && _isPlaying;
              final isCurrent = _currentSong?.id == song.id;
              return GestureDetector(
                onTap: () => _playSong(song),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent ? _primary.withValues(alpha: 0.08) : _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isCurrent ? _primary : _accent,
                        width: isCurrent ? 1.5 : 1),
                    boxShadow: [BoxShadow(
                        color: _primary.withValues(alpha: 0.06),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    RotationTransition(
                      turns: isCurrent && _isPlaying
                          ? _rotationController
                          : const AlwaysStoppedAnimation(0),
                      child: Container(width: 50, height: 50,
                          decoration: BoxDecoration(color: song.cardColor, shape: BoxShape.circle),
                          child: Icon(song.icon, color: Colors.white, size: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(song.title, style: TextStyle(
                          color: isCurrent ? _primary : _textDark,
                          fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(song.artist, style: const TextStyle(color: _textGrey, fontSize: 12)),
                      const SizedBox(height: 5),
                      Row(children: [
                        _chip(song.language, _primary),
                        const SizedBox(width: 6),
                        _chip(song.deity, const Color(0xFFBF360C)),
                      ]),
                    ])),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      GestureDetector(
                        onTap: () => _openLyrics(song),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: _accent, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Lyrics', style: TextStyle(
                              color: _primary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                            color: isCurrent ? _primary : _accent,
                            shape: BoxShape.circle),
                        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isCurrent ? Colors.white : _primary, size: 18),
                      ),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),

        // ── Now Playing Bar ──
        if (_currentSong != null)
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              border: const Border(top: BorderSide(color: _primary, width: 2)),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(children: [
              // Seek slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _progress.clamp(0.0, 1.0),
                  onChanged: (v) async {
                    final pos = Duration(milliseconds: (_duration.inMilliseconds * v).toInt());
                    await _player.seek(pos);
                  },
                  activeColor: _primary,
                  inactiveColor: _accent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_fmt(_position), style: const TextStyle(color: _textGrey, fontSize: 11)),
                  Text(_fmt(_duration), style: const TextStyle(color: _textGrey, fontSize: 11)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(children: [
                  Container(width: 40, height: 40,
                      decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                      child: Icon(_currentSong!.icon, color: _primary, size: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_currentSong!.title,
                        style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_currentSong!.artist,
                        style: const TextStyle(color: _textGrey, fontSize: 11)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: _primary, size: 26),
                    onPressed: () {
                      final idx = _allSongs.indexWhere((s) => s.id == _currentSong!.id);
                      if (idx > 0) _playSong(_allSongs[idx - 1]);
                    },
                  ),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: _primary, size: 26),
                    onPressed: () {
                      final idx = _allSongs.indexWhere((s) => s.id == _currentSong!.id);
                      if (idx < _allSongs.length - 1) _playSong(_allSongs[idx + 1]);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.lyrics_outlined, color: _textGrey, size: 20),
                    onPressed: () => _openLyrics(_currentSong!),
                  ),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4))),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}