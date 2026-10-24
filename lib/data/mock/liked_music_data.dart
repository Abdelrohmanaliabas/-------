import '../../domain/models/song.dart';

class LikedMusicData {
  LikedMusicData._();

  static List<Song> get songs => likedSongs;

  static const List<Song> likedSongs = [
    // 1. Ahmed Saad - Ekhtyaraty
    Song(
      id: 'liked_ekhtyaraty',
      title: 'اختياراتي',
      artist: 'أحمد سعد',
      album: 'مستر إكس',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/f3e8281a7b45873967d1db0928a7e089/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/2024/Albumaty.Com_ahmd_sad_ekhtyaraty_-_rymks.mp3',
      duration: Duration(minutes: 3, seconds: 12),
      genre: 'طرب شعبي',
      isFavorite: true,
      playsCount: 54000000,
      releaseYear: '2023',
    ),

    // 2. Amr Diab - Tamally Maak
    Song(
      id: 'liked_tamally_maak',
      title: 'تملي معاك',
      artist: 'عمرو دياب',
      album: 'تملي معاك',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/a479b38466b0a1d520330a108a7b6ad7/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/3en/amr-diab/albums/tamaly-m3ak/02.Tamally_Maak.mp3',
      duration: Duration(minutes: 4, seconds: 31),
      genre: 'بوب عربي',
      isFavorite: true,
      playsCount: 98000000,
      releaseYear: '2000',
    ),

    // 3. Hussain Al Jassmi - Bel Bont El Areed
    Song(
      id: 'liked_bel_bont_el_areed',
      title: 'بالبنط العريض',
      artist: 'حسين الجسمي',
      album: 'بالبنط العريض',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/3bce3d93fce7e0a2a36cf34f5f5a7e98/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_hsyn_algsmy_balbnt_alaryd.mp3',
      duration: Duration(minutes: 3, seconds: 43),
      genre: 'بوب خليجي',
      isFavorite: true,
      playsCount: 120000000,
      releaseYear: '2020',
    ),

    // 4. Sherine - Hobboh Ganna
    Song(
      id: 'liked_hobboh_ganna',
      title: 'حبه جنة',
      artist: 'شيرين عبد الوهاب',
      album: 'نساي',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/e5ab08f782135c3cc88289ac8a8bf7be/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/shen/sherine/albums/nsay/05._Hobboh_Ganna.mp3',
      duration: Duration(minutes: 4, seconds: 15),
      genre: 'طرب رومانسي',
      isFavorite: true,
      playsCount: 64000000,
      releaseYear: '2018',
    ),

    // 5. Hamza Namira - Fady Shewaya
    Song(
      id: 'liked_fady_shewaya',
      title: 'فاضي شوية',
      artist: 'حمزة نمرة',
      album: 'مولود سنة 80',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/79ec18a8ec2eb4989eda6d13df12ec99/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_hmzh_nmrh_fady_shwyt.mp3',
      duration: Duration(minutes: 4, seconds: 42),
      genre: 'طرب معاصر',
      isFavorite: true,
      playsCount: 88000000,
      releaseYear: '2020',
    ),

    // 6. Amr Diab - Enta El Haz
    Song(
      id: 'liked_enta_el_haz',
      title: 'انت الحظ',
      artist: 'عمرو دياب',
      album: 'عيشني',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/6c230353c7c34614619ad17537b8cb21/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_Amr_Diab_Enta_Elhaz.mp3',
      duration: Duration(minutes: 3, seconds: 40),
      genre: 'بوب عربي',
      isFavorite: true,
      playsCount: 71000000,
      releaseYear: '2021',
    ),

    // 7. Tamer Ashour - Ouloulo Samah
    Song(
      id: 'liked_ouloulo_samah',
      title: 'قولوله سماح',
      artist: 'تامر عاشور',
      album: 'أيام',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/8e2f2dc6ee5a4f9c5cc2e5e7b4a5d3f2/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/th/tamer-ashour/albums/ayaam/05._Oloolo_Samah.mp3',
      duration: Duration(minutes: 3, seconds: 49),
      genre: 'طرب درامي',
      isFavorite: true,
      playsCount: 51000000,
      releaseYear: '2019',
    ),

    // 8. Assala - Ghalban
    Song(
      id: 'liked_ghalban',
      title: 'غلبان',
      artist: 'أصالة',
      album: 'غلبان',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/9346f66804541490beca47721268cd7c/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_asalt_ghlban.mp3',
      duration: Duration(minutes: 3, seconds: 45),
      genre: 'طرب أصيل',
      isFavorite: true,
      playsCount: 69000000,
      releaseYear: '2022',
    ),

    // 9. Mohamed Hamaki - Ya Sattar
    Song(
      id: 'liked_ya_sattar',
      title: 'يا ستار',
      artist: 'محمد حماقي',
      album: 'كل يوم من ده',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/ba98ee615c5867d2f5ca252e215c039c/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/mem/mohamed-hamaki/albumes/kol-youm-mn-dah/10._Ya_Sattar.mp3',
      duration: Duration(minutes: 3, seconds: 54),
      genre: 'بوب رومانسي',
      isFavorite: true,
      playsCount: 63000000,
      releaseYear: '2019',
    ),

    // 10. Sherine - El Watar El Hassas
    Song(
      id: 'liked_el_watar_el_hassas',
      title: 'الوتر الحساس',
      artist: 'شيرين عبد الوهاب',
      album: 'نساي',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/e5ab08f782135c3cc88289ac8a8bf7be/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/shen/sherine/albums/nsay/06._El_Watar_El_Hassas.mp3',
      duration: Duration(minutes: 3, seconds: 47),
      genre: 'طرب ورومانسي',
      isFavorite: true,
      playsCount: 59000000,
      releaseYear: '2018',
    ),

    // 11. Bahaa Sultan - Delwa'ty Agabnakoo
    Song(
      id: 'liked_delwaty_agabnakoo',
      title: 'دلوقتي عجبناكوا',
      artist: 'بهاء سلطان',
      album: 'دلوقتي عجبناكوا',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/0c92030549ec798f882778d7d127e316/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/song2022/Albumaty.Com_bhaa_sltan_dlwkty_agbnakw.mp3',
      duration: Duration(minutes: 4, seconds: 6),
      genre: 'طرب شعبي',
      isFavorite: true,
      playsCount: 42000000,
      releaseYear: '2022',
    ),

    // 12. Cairokee - Telka Qadeya
    Song(
      id: 'liked_telka_qadeya',
      title: 'تلك قضية',
      artist: 'كايروكي',
      album: 'تلك قضية',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/123994eb2834a27c0832210a7cce6e16/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/song2022/Albumaty.Com_kayrwky_tlk_kdyt.mp3',
      duration: Duration(minutes: 3, seconds: 50),
      genre: 'روك عربي',
      isFavorite: true,
      playsCount: 38000000,
      releaseYear: '2023',
    ),

    // 13. Nancy Ajram - Salamat
    Song(
      id: 'liked_salamat',
      title: 'سلامات',
      artist: 'نانسي عجرم',
      album: 'نانسي 10',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/9bce0ee0ca1ec88e6a8d72e1d3f6ce8c/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_nansy_agrm_slamat.mp3',
      duration: Duration(minutes: 3, seconds: 12),
      genre: 'بوب عربي',
      isFavorite: true,
      playsCount: 44000000,
      releaseYear: '2021',
    ),

    // 14. Cairokee - Roma
    Song(
      id: 'liked_roma',
      title: 'روما',
      artist: 'كايروكي',
      album: 'روما',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/0c512f03395b278ec87502f7a5d0ff4f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/song2022/Albumaty.Com_kayrwky_rwma.mp3',
      duration: Duration(minutes: 3, seconds: 48),
      genre: 'روك بديل',
      isFavorite: true,
      playsCount: 36000000,
      releaseYear: '2022',
    ),

    // 15. Ahmed Saad - Sayrena Ya Donya
    Song(
      id: 'liked_sayrena_ya_donya',
      title: 'سايرينا يا دنيا',
      artist: 'أحمد سعد',
      album: 'من أجل زيكو',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/2ec20135cb3ddcbeb83dae4ab32d3f5f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv2.albumaty.com/2025/Albumaty.Com_ahmd_sad_aldnya_ywmyn.mp3',
      duration: Duration(minutes: 3, seconds: 35),
      genre: 'طرب شعبي',
      isFavorite: true,
      playsCount: 67000000,
      releaseYear: '2022',
    ),

    // 16. Amr Diab - Ya Ana Ya La
    Song(
      id: 'liked_ya_ana_ya_la',
      title: 'يا أنا يا لأ',
      artist: 'عمرو دياب',
      album: 'يا أنا يا لأ',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/a479b38466b0a1d520330a108a7b6ad7/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_amrw_dyab_ya_ana_ya_laa_-_rymks.mp3',
      duration: Duration(minutes: 3, seconds: 53),
      genre: 'بوب عربي',
      isFavorite: true,
      playsCount: 52000000,
      releaseYear: '2020',
    ),

    // 17. Sherine - Masha'er
    Song(
      id: 'liked_mashaer',
      title: 'مشاعر',
      artist: 'شيرين عبد الوهاب',
      album: 'حكاية حياة',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/e5ab08f782135c3cc88289ac8a8bf7be/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/shen/shereen/singels/Albumaty.Com.Sherine.Masha3er.mp3',
      duration: Duration(minutes: 4, seconds: 35),
      genre: 'طرب درامي',
      isFavorite: true,
      playsCount: 75000000,
      releaseYear: '2013',
    ),

    // 18. Hamza Namira - Dari Ya Alby
    Song(
      id: 'liked_dari_ya_alby',
      title: 'داري يا قلبي',
      artist: 'حمزة نمرة',
      album: 'هطير من تاني',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/79ec18a8ec2eb4989eda6d13df12ec99/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/dl/7h/hamza-namira/albumes/hteer-mn-tany/03_._Dari_Ya_Alby_%5b_Acoustic_Version_%5d.mp3',
      duration: Duration(minutes: 4, seconds: 20),
      genre: 'طرب معاصر',
      isFavorite: true,
      playsCount: 92000000,
      releaseYear: '2018',
    ),

    // 19. Tamer Hosny - Hadala3ny
    Song(
      id: 'liked_hadala3ny',
      title: 'هدلعني',
      artist: 'تامر حسني',
      album: 'بحبك',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/4d793556d3eb846d6e503b1999e4916d/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_tamr_hsni_hdlany_-_mn_fylm_bhbk.mp3',
      duration: Duration(minutes: 3, seconds: 40),
      genre: 'بوب رومانسي',
      isFavorite: true,
      playsCount: 48000000,
      releaseYear: '2022',
    ),

    // 20. Assala - Shukran
    Song(
      id: 'liked_shukran',
      title: 'شكراً',
      artist: 'أصالة',
      album: 'برنامج الدوم',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/9346f66804541490beca47721268cd7c/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_asalt_shkra_-_mn_brnamg_aldwm.mp3',
      duration: Duration(minutes: 3, seconds: 35),
      genre: 'طرب أصيل',
      isFavorite: true,
      playsCount: 39000000,
      releaseYear: '2022',
    ),

    // 21. Tamer Hosny - Eish Besho'ak
    Song(
      id: 'liked_eish_beshoak',
      title: 'عيش بشوقك',
      artist: 'تامر حسني',
      album: 'عيش بشوقك',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/4d793556d3eb846d6e503b1999e4916d/500x500-000000-80-0-0.jpg',
      audioUrl: "https://serv100.albumaty.com/dl/th/tamer-hosny/albums/eish-besho2ak/05._Eish_Besho'ak.mp3",
      duration: Duration(minutes: 3, seconds: 50),
      genre: 'طرب شعبي',
      isFavorite: true,
      playsCount: 77000000,
      releaseYear: '2018',
    ),

    // 22. Ahmed Saad - Wasa3 Wasa3
    Song(
      id: 'liked_wasa3_wasa3',
      title: 'وسع وسع',
      artist: 'أحمد سعد',
      album: 'وسع وسع',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/55cb6633ae9b1a4dfa168b72707747d7/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_ahmd_sad_wsa_wsa.mp3',
      duration: Duration(minutes: 3, seconds: 18),
      genre: 'طرب شعبي',
      isFavorite: true,
      playsCount: 48000000,
      releaseYear: '2022',
    ),

    // 23. Ahmed Saad - Eh El Youm El Helw Dah
    Song(
      id: 'liked_elyoum_elhelw',
      title: 'إيه اليوم الحلو ده',
      artist: 'أحمد سعد',
      album: 'عمهم',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/2ec20135cb3ddcbeb83dae4ab32d3f5f/500x500-000000-80-0-0.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_ahmd_sad_alywm_alhlw_dh_-_mn_fylm_amhm.mp3',
      duration: Duration(minutes: 3, seconds: 10),
      genre: 'طرب شعبي',
      isFavorite: true,
      playsCount: 52000000,
      releaseYear: '2022',
    ),

    // 24. Wegz - El Bakht
    Song(
      id: 'liked_el_bakht',
      title: 'البخت',
      artist: 'ويجز',
      album: 'البخت',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/e2/07/3b/e2073b69-e9a9-0377-2a37-8eabccbc8ef5/6221216329950.jpg/600x600bb.jpg',
      audioUrl: 'https://serv100.albumaty.com/songs_2020/Albumaty.Com_wygz_albkht.mp3',
      duration: Duration(minutes: 3, seconds: 50),
      genre: 'تراب عربي',
      isFavorite: true,
      playsCount: 75000000,
      releaseYear: '2022',
    ),
  ];
}
