import '../../domain/models/song.dart';

class LikedMusicData {
  LikedMusicData._();

  static List<Song> get songs => likedSongs;

  static const List<Song> likedSongs = [
    // 1. Aboya A'al
    Song(
      id: 'liked_aboya_aal',
      title: "Aboya A'al",
      artist: 'Mr Kordy & 3amo klay - عمو كلاي',
      album: 'أبويا قال',
      artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 6),
      genre: 'شعبي',
      isFavorite: true,
      playsCount: 1540000,
      releaseYear: '2024',
    ),

    // 2. KALAMANTINA
    Song(
      id: 'liked_kalamantina',
      title: 'KALAMANTINA / كلمنتينا',
      artist: 'Saint Levant & Marwan Moussa',
      album: 'DEIRA',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/6c230353c7c34614619ad17537b8cb21/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 27),
      genre: 'هيب هوب عربي',
      isFavorite: true,
      playsCount: 8900000,
      releaseYear: '2024',
    ),

    // 3. Khamsa (feat. FL EX)
    Song(
      id: 'liked_khamsa',
      title: 'Khamsa (feat. FL EX)',
      artist: 'Wingii',
      album: 'خمسة',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/f3e8281a7b45873967d1db0928a7e089/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 19),
      genre: 'تراب عربي',
      isFavorite: true,
      playsCount: 6200000,
      releaseYear: '2023',
    ),

    // 4. Saint Levant - Kalamantina (DJ Zee Remix)
    Song(
      id: 'liked_kalamantina_zee_remix',
      title: 'Saint Levant - Kalamantina (DJ Zee Remix)',
      artist: 'DJ ZEE',
      album: 'Kalamantina Remixes',
      artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 5),
      genre: 'ريمكس',
      isFavorite: true,
      playsCount: 2100000,
      releaseYear: '2024',
    ),

    // 5. Kalamantina (Dabke Edit)
    Song(
      id: 'liked_kalamantina_dabke',
      title: 'Kalamantina (Dabke Edit)',
      artist: 'ZeeKaa & Kahraba',
      album: 'Dabke Edits',
      artworkUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 41),
      genre: 'دبكة',
      isFavorite: true,
      playsCount: 1800000,
      releaseYear: '2024',
    ),

    // 6. Maleket Gamal El Kon
    Song(
      id: 'liked_maleket_gamal_el_kon',
      title: 'Maleket Gamal El Kon',
      artist: 'Tamer Hosny & Al Shami',
      album: 'ملكة جمال الكون',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/2e3a7c9d5f1b4e6a8c0d2f4b6e8a0c2d/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 54),
      genre: 'بوب عربي',
      isFavorite: true,
      playsCount: 11500000,
      releaseYear: '2024',
    ),

    // 7. Ahlam song | IZZ ft. Emy | أغنية أحلام
    Song(
      id: 'liked_ahlam_song',
      title: 'Ahlam song | IZZ ft. Emy | أغنية أحلام',
      artist: 'عزالدين الشويخ',
      album: 'أحلام',
      artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 5, seconds: 1),
      genre: 'موسيقى وتوزيع',
      isFavorite: true,
      playsCount: 3400000,
      releaseYear: '2023',
    ),

    // 8. Moukawem
    Song(
      id: 'liked_moukawem',
      title: 'Moukawem',
      artist: 'Julia Boutros',
      album: 'مقاوم',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/8e2f2dc6ee5a4f9c5cc2e5e7b4a5d3f2/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 26),
      genre: 'طرب وطني',
      isFavorite: true,
      playsCount: 4700000,
      releaseYear: '2016',
    ),

    // 9. Razmen Khamsa
    Song(
      id: 'liked_razmen_khamsa',
      title: 'Razmen Khamsa',
      artist: 'Showkey & Mvrslino Muzik',
      album: 'رزمن خمسة',
      artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 26),
      genre: 'تراب مصري',
      isFavorite: true,
      playsCount: 1950000,
      releaseYear: '2023',
    ),

    // 10. KOFIA - Leve Palestina (RAEVION)
    Song(
      id: 'liked_leve_palestina',
      title: 'KOFIA - Leve Palestina (RAEVION)',
      artist: 'RAEVION',
      album: 'Leve Palestina',
      artworkUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 33),
      genre: 'وطني',
      isFavorite: true,
      playsCount: 5200000,
      releaseYear: '2023',
    ),

    // 11. El Kemya Rakba Men Bernameg Beit El Saad
    Song(
      id: 'liked_el_kemya_rakba',
      title: 'El Kemya Rakba Men Bernameg Beit El Saad',
      artist: 'Ahmed Saad',
      album: 'بيت السعد',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/ba98ee615c5867d2f5ca252e215c039c/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 1, seconds: 32),
      genre: 'بوب شعبي',
      isFavorite: true,
      playsCount: 14200000,
      releaseYear: '2024',
    ),

    // 12. متعلمشي
    Song(
      id: 'liked_met3allemshi',
      title: 'متعلمشي',
      artist: '7ob 3omRy ... أويتى بنتى اوزعتى عم الحج',
      album: 'حب عمري',
      artworkUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 45),
      genre: 'مهرجانات',
      isFavorite: true,
      playsCount: 2300000,
      releaseYear: '2023',
    ),

    // 13. Ya Albo
    Song(
      id: 'liked_ya_albo',
      title: 'Ya Albo',
      artist: 'Nancy Ajram',
      album: 'يا قلبو',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/9bce0ee0ca1ec88e6a8d72e1d3f6ce8c/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 31),
      genre: 'بوب عربي',
      isFavorite: true,
      playsCount: 8700000,
      releaseYear: '2024',
    ),

    // 14. Wewa Wewa Double Zuksh ft Elsawarekh
    Song(
      id: 'liked_wewa_wewa',
      title: 'Wewa Wewa Double Zuksh ft Elsawarekh',
      artist: 'دبل زوكش -ويوا ويوا Do2aa',
      album: 'ويوا ويوا',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/e5ab08f782135c3cc88289ac8a8bf7be/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 15),
      genre: 'مهرجانات',
      isFavorite: true,
      playsCount: 7100000,
      releaseYear: '2024',
    ),

    // 15. Walaana
    Song(
      id: 'liked_walaana',
      title: 'Walaana',
      artist: 'Ahmed Mekky',
      album: 'الكبير أوي 7',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/0c92030549ec798f882778d7d127e316/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 53),
      genre: 'راب مصري',
      isFavorite: true,
      playsCount: 28000000,
      releaseYear: '2023',
    ),

    // 16. اغنية سلامك كلامك وضحكت عيونك راموني في هواك
    Song(
      id: 'liked_salamak_kalamak',
      title: 'اغنية سلامك كلامك وضحكت عيونك راموني في هواك',
      artist: 'the top 111',
      album: 'سلامك كلامك',
      artworkUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 5, seconds: 11),
      genre: 'طرب رومانسي',
      isFavorite: true,
      playsCount: 3900000,
      releaseYear: '2024',
    ),

    // 17. KUNTU MAYITAN
    Song(
      id: 'liked_kuntu_mayitan',
      title: 'KUNTU MAYITAN',
      artist: 'DJ ANAS',
      album: 'كنت ميتا',
      artworkUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 5, seconds: 28),
      genre: 'نشيد وريمكس',
      isFavorite: true,
      playsCount: 4600000,
      releaseYear: '2023',
    ),

    // 18. Werge3na Lewaga3 El Alb
    Song(
      id: 'liked_werge3na_lewaga3_el_alb',
      title: 'Werge3na Lewaga3 El Alb',
      artist: 'Hamza Namira',
      album: 'رايق',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/79ec18a8ec2eb4989eda6d13df12ec99/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 9),
      genre: 'إندي بوب',
      isFavorite: true,
      playsCount: 16500000,
      releaseYear: '2023',
    ),

    // 19. Mardaani Anthem
    Song(
      id: 'liked_mardaani_anthem',
      title: 'Mardaani Anthem',
      artist: 'Sunidhi Chauhan & Vijay Prakash',
      album: 'Mardaani',
      artworkUrl: 'https://images.unsplash.com/photo-1487180144351-b8472da7d491?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 30),
      genre: 'بوليوود',
      isFavorite: true,
      playsCount: 9200000,
      releaseYear: '2014',
    ),

    // 20. في وحدتي (مع هند السامعي)
    Song(
      id: 'liked_fi_wahdati',
      title: 'في وحدتي (مع هند السامعي)',
      artist: 'عزالدين الشويخ',
      album: 'في وحدتي',
      artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 4, seconds: 52),
      genre: 'طرب معاصر',
      isFavorite: true,
      playsCount: 4100000,
      releaseYear: '2023',
    ),

    // 21. Daddy Yankee - Gasolina Egyption Remix | Zork Remix
    Song(
      id: 'liked_gasolina_egyptian_remix',
      title: 'Daddy Yankee - Gasolina Egyption Remix | Zork Remix',
      artist: 'zork music',
      album: 'Egyptian Remixes',
      artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 18),
      genre: 'ريمكس',
      isFavorite: true,
      playsCount: 7800000,
      releaseYear: '2024',
    ),

    // 22. Albi Elgamed - قلبي الجامد
    Song(
      id: 'liked_albi_elgamed',
      title: 'Albi Elgamed - قلبي الجامد',
      artist: 'Yehia Alaa',
      album: 'قلبي الجامد',
      artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 41),
      genre: 'بوب مصري',
      isFavorite: true,
      playsCount: 3200000,
      releaseYear: '2023',
    ),

    // 23. MESH HA'OUL - مش هقول
    Song(
      id: 'liked_mesh_haoul',
      title: "MESH HA'OUL - مش هقول",
      artist: 'Hamada Helal',
      album: 'مش هقول',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/123994eb2834a27c0832210a7cce6e16/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 4, seconds: 7),
      genre: 'بوب طربي',
      isFavorite: true,
      playsCount: 5600000,
      releaseYear: '2024',
    ),

    // 24. يارا محمد - شيفاكوا هوا ( اخصامي كتيرة مابعتمدش حد انا )
    Song(
      id: 'liked_shefakoo_hawa',
      title: 'يارا محمد - شيفاكوا هوا ( اخصامي كتيرة مابعتمدش حد انا )',
      artist: 'Yara Mohamed',
      album: 'شيفاكوا هوا',
      artworkUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 14),
      genre: 'شعبي مصري',
      isFavorite: true,
      playsCount: 6800000,
      releaseYear: '2024',
    ),

    // 25. خالد بن الوليد
    Song(
      id: 'liked_khaled_ibn_al_walid',
      title: 'خالد بن الوليد',
      artist: 'أنس البرقي',
      album: 'سير الأبطال',
      artworkUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 1, seconds: 35),
      genre: 'أناشيد وحماسي',
      isFavorite: true,
      playsCount: 2900000,
      releaseYear: '2024',
    ),

    // 26. الحب اللي كان - نسخة قصيرة
    Song(
      id: 'liked_al_hob_elli_kan',
      title: 'الحب اللي كان - نسخة قصيرة',
      artist: 'Abdullah',
      album: 'الحب اللي كان',
      artworkUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 53),
      genre: 'طرب كلاسيك',
      isFavorite: true,
      playsCount: 3100000,
      releaseYear: '2024',
    ),

    // 27. REVENGE (Super Slowed)
    Song(
      id: 'liked_revenge_super_slowed',
      title: 'REVENGE (Super Slowed)',
      artist: '1HXSK & wnorg17',
      album: 'REVENGE',
      artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 2, seconds: 2),
      genre: 'فونك',
      isFavorite: true,
      playsCount: 4400000,
      releaseYear: '2023',
    ),

    // 28. شارموفرز - أغنية فيلم هيبتا - 6,5 هيبتا
    Song(
      id: 'liked_hepta_song',
      title: 'شارموفرز - أغنية فيلم هيبتا - 6,5 هيبتا',
      artist: 'Sharmoofers & Hadi ElBagoury',
      album: 'هيبتا',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/3bce3d93fce7e0a2a36cf34f5f5a7e98/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 7),
      genre: 'ألتيرناتيف إندي',
      isFavorite: true,
      playsCount: 19000000,
      releaseYear: '2016',
    ),

    // 29. لو تعرفو
    Song(
      id: 'liked_lo_te3rafo',
      title: 'لو تعرفو',
      artist: 'لو تعرفو',
      album: 'لو تعرفو',
      artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 15),
      genre: 'طرب كلاسيكي',
      isFavorite: true,
      playsCount: 2200000,
      releaseYear: '2023',
    ),

    // 30. Eskndarany Ana
    Song(
      id: 'liked_eskndarany_ana',
      title: 'Eskndarany Ana',
      artist: 'Houda Bondok & حوده شيبه',
      album: 'اسكندراني أنا',
      artworkUrl: 'https://cdn-images.dzcdn.net/images/cover/ba98ee615c5867d2f5ca252e215c039c/500x500-000000-80-0-0.jpg',
      audioUrl: '',
      duration: Duration(minutes: 3, seconds: 35),
      genre: 'شعبي مصري',
      isFavorite: true,
      playsCount: 8400000,
      releaseYear: '2024',
    ),
  ];
}
