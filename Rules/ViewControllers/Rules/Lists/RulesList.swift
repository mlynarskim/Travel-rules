//  Created by Mateusz Mlynarski
// All rights reserved 

import Foundation

// English Rules
let RulesList = [
    "1. Invest in a good mattress - sleep is very important for your health and well-being.",
    "2. It's a good idea to have a basic tool case in your car - even if you can't fix your car yourself, someone can help you.",
    "3. Prepare a list of things you need to take with you before every trip.",
    "4. always have a first aid kit with you.",
    "5. Plan your trips in advance and pay attention to weather conditions.",
    "6. Learn how to use different energy sources - from solar panels to a generator.",
    "7. Always have enough drinking water with you.",
    "8. Test all equipment in your camper or trailer before your first trip.",
    "9. Learn how the drainage system works and how to take care of hygiene.",
    "10. Always lock the doors and windows when you leave the camper or trailer.",
    "11. Remember to regularly service and inspect your camper or trailer.",
    "12. Stock up on necessary medications such as painkillers and activated charcoal.",
    "13. check the technical condition of your vehicle before you leave.",
    "14. If you're heading out into the countryside, even when it's summer on the ground, drive on winter tires.",
    "15. Always have a bottle of motor oil dedicated to your vehicle in your car.",
    "16. A difficult access road usually hides a great wild spot at the end.",
    "17. Take care and think of others, if you park between other campers, keep .adequate distance.",
    "18. if you're going out for a walk in the late afternoon, take a flashlight or powerbench with a cable for your phone. ",
    "19. If you get confused on the road, don't turn back, let yourself be adventurous, but of course with caution.",
    "20. if you go uphill in 2nd gear, you should also go downhill in 2nd gear",
    "21. if you are traveling alone, share your location frequently with your immediate family",
    "22. if you have the opportunity to refill water, pour out gray, black water, do it. You may find that the nearest nearest service center is not on the way.",
    "23. If you are traveling with another person, always establish a way of communication between you in case you get lost or separated.",
    "24. Take your garbage with you if there is no trash can nearby.",
    "25.A long hose for refueling water is always better than a short one.",
    "26. It's a good idea to get a variety of screw-on tips for water valves, you never know what you'll find on site.",
    "27. The road to the sleeping place was downhill? Check the weather, if it's supposed to rain change to another place, in the morning you may have trouble leaving.",
    "28. Never stop when someone waves at you whether on a regular road or highway.",
    "29. Save money, water, gas and electricity.",
    "30. Minimalism is your friend. When packing for a long trip, don't take unnecessary things with you. In time you will notice that you don't lack them at all.",
    "31. Planning. If you have found a super spot on google maps or park4night check to see if there are other interesting places next to it. You may find that the place is no longer available for overnight stays.",
    "32. Safety. If you have arrived at a place and do not feel safe there, change to another place.",
    "33. in a pile is better. If you don't feel safe in the area you happen to be in, look around for other campers, it will be safer to stand somewhere with more campers.",
    "34. Treasures. Find a place in your car for your valuables, you can install a small safe or a metal lockable box. Remember to properly secure it against theft.",
    "35. Respect the environment: Take care of the environment in which you travel. Follow environmental rules, such as leaving the place clean and segregating trash.",
    "36. Enjoy your freedom: Enjoy the freedom and adventure that van life offers. Make your trip an amazing adventure and an experience that you will always remember. Live this moment!",
    "37. Culture and tradition. Remember to respect local cultures and traditions.",
    "38. Observe the traffic laws of the country you are traveling through. Avoid fines.",
    "39. Limit your use of plastic disposable items.",
    "40. When traveling for a long time, make short stops to stretch, you can also change the position of your seat, this will give relief to your spine.",
    "41. Be flexible and open to changes in plans, as something unpredictable can always come up when traveling.",
    "42. Be prepared for lack of phone or internet coverage in some places.",
    "43. Remember to rest and relax, not just travel non-stop.",
    "44. Before traveling to a country, download offline maps not only of the destination country but also of those you will be passing through.",
    "45. install appropriate apps to find places to sleep (GoogleMaps, Park4Night, etc.).",
    "46. Always carry enough cash or debit card to pay for travel expenses.",
    "47. Divide larger amounts of cash into several smaller ones and stash them in unobtrusive places. The car glove box is the first thing a potential thief will check.",
    "48. Set a good example. If you see trash left by others, try to pick it up and dispose of it in an appropriate place.",
    "49. Buy travel insurance, assistance, towing.",
    "50. Take care of your safety and the safety of your loved ones, always wear a seat belt and avoid driving after drinking alcohol.",
    "51. Take advantage of opportunities to meet new people and experience different cultures by sharing your experiences with others.",
    "52. Be ready for unforeseen expenses, such as car repairs or buying extra fuel.",
    "53. If you don't have an idea of a place to stop for the night, you can ask about the possibility of stopping at a gas station, for example.",
    "54. Be prepared for different road conditions, such as rocky roads, high mountains or roads with sharp curves.",
    "55. Observe the rules for entering national parks or other protected areas so that you don't put nature in harm's way and yourself in additional expense.",
    "56. Be patient when driving and encounter difficult roads, a crowd of people or car problems that may cause delays in your trip.",
    "57. Souvenirs. Be sure to leave some room for items purchased on your trip.",
    "58. Explore not only new places, try local cuisine as well. Open yourself up to new flavors, you may come back from your trip with a new favorite dish.",
    "59. Follow camping rules, such as leaving the site in the condition you found it, and obeying rules about campfires and barbecues.",
    "60. avoid environmental pollution, try using eco-friendly cosmetics",
    "61. you can minimize water consumption by using public sources, including toilets and showers.",
    "62. Try to learn new skills such as campfire cooking, climbing or surfing to broaden your horizons and enjoy your trip more.",
    "63. Small towns or villages in the area where you are currently staying may be a better attraction for you than a crowded tourist city.",
    "64. It's a good idea to always have basic foodstuffs such as flour, yeast, sugar and salt in your car.",
    "65. Learn from your mistakes and don't stop experimenting with different solutions.",
    "66. Remember to use your free time to develop your interests and passions, whether through reading, learning languages or creating art.",
    "67. Enjoy nature and allow yourself moments of reflection and meditation to gain new perspectives on your life and goals.",
    "68. Be ready for unexpected challenges and situations, and that it won't always be easy.",
    "69. If you are traveling alone, stay sober, you don't know if the Police will not come and order you to repark your car.",
    "70. Don't get into a discussion with local police and residents. Respect them.",
    "71. Be grateful for every moment and every experience that meets you on your journey, and for every person who comes into your life and shares their stories and wisdom with you.",
    "72. remember that traveling by car involves some risk, so always be alert and careful on the road.",
    "73. Take care of your relationships with family and friends by keeping in touch with them and sharing your experiences.",
    "74. Be open to learning and personal development, using your time in the car to listen to audiobooks, podcasts or learn new skills.",
    "75. Watch out for pickpockets on public transportation. Always keep an eye on your luggage.",
    "76. If you're traveling with a pet make sure it's at the right temperature and has access to drinking water.",
    "77. Replace chemical toiletries with eco-friendly ones such as sachets or septic tank tablets.",
    "78. Do not leave your hiking equipment (Chairs, table, grill) outside overnight.",
    "79. be humble/be humble to locals and all passersby. Smile! You are part of their daily routine, their place and home grounds.",
    "80. Be kind to locals. Chances are you will need their help if you have an unexpected problem.",
    "81. A drone is a great device for creating travel souvenirs. Remember to keep other people safe and private.",
    "82. If you have a drone, check the current regulations in the country you are in. Observe flight bans in designated areas.",
    "83. If you have a drone, never take off near an airport.",
    "84. Don't obstruct the view from someone's house, restaurant or terrace.",
    "85. If your van/caravan takes up more than one parking space, park elsewhere.",
    "86. read/translate information on signs.",
    "87. Sometimes finding a parking space can be a problem. You can ask locals or the police for a convenient place to stay.",
    "88. Start writing a travel journal, it can be a great souvenir.",
    "89. Take a board game or cards with you, it will add variety to your time during bad weather.",
    "90. ?Approach each day strategically,? Plan shopping, servicing, emptying the toilet and gray water the day before.",
    "91. cooking in an RV/campervan takes much more time than in a stir-fry.",
    "92. Be prepared to clean the car frequently. Stock up on a sweeper or vacuum cleaner.",
    "93. Be prepared for numerous insects, not just mosquitoes. A mosquito net may be only a partial solution.",
    "94. Don't turn on a light in the evening with the door ajar.",
    "95. Before you leave, check the condition of your spare wheel, and you can also get a tire repair kit. This will allow you to reach the nearest vulcanization.",
    "96. Be ready to step out of your comfort zone.",
    "97. If you work remotely, make sure you have a comfortable place to work. A lounger and a beach looks cool only in pictures.",
    "98. Every day is an adventure. Treat it as a good time.",
    "99. If you travel with a pet, keep it close to your car.",
    "100. When there is no coverage on your phone, it is a good idea to have a paper map with you.",
    "101. Weather conditions during a walk can change suddenly, and it is advisable to bring a raincoat that can fit in your pocket.",
    "102. Before traveling, check the validity of your passport and other documents.",
    "103. Get a European Health Insurance Card (EHIC) LINK.",
    "104. Bring a small kettle to boil water for coffee to save time and water.",
    "105. Remember UV sunscreen, in summer, winter and even when you go to the mountains.",
    "106. Make a shopping list you will avoid unnecessary/additional expenses.",
    "107. Don't pack at the last minute, prepare the necessary items at least two days in advance,",
    "108. A bottle of alcohol or other gift is a good idea to give as a thank you for your help?"]

    let RulesListPL: [String] = [
        "1. Zainwestuj w dobry materac - sen jest bardzo ważny dla Twojego zdrowia i samopoczucia.",
        "2. Warto mieć w aucie podstawową walizkę z narzędziami, nawet jeśli sam nie potrafisz naprawić swojego samochodu, ktoś może Ci pomóc.",
        "3. Przygotuj listę rzeczy, które musisz zabrać ze sobą przed każdym wyjazdem.",
        "4. Zawsze miej ze sobą zestaw pierwszej pomocy.",
        "5. Planuj swoje wyjazdy z wyprzedzeniem i zwracaj uwagę na warunki atmosferyczne.",
        "6. Naucz się, jak korzystać z różnych źródeł energii - od paneli słonecznych, po generator.",
        "7. Zawsze miej ze sobą wystarczającą ilość wody pitnej.",
        "8. Przetestuj wszystkie urządzenia w kamperze lub przyczepie przed wyjazdem.",
        "9. Naucz się jak działa system odprowadzania ściekóww w twoim kamperze lub przyczepie.",
        "10. Zawsze zamykaj drzwi i okna, kiedy opuszczasz kampera lub przyczepę.",
        "11. Pamiętaj o regularnym serwisowaniu i przeglądach kampera lub przyczepy.",
        "12. Zaopatrz się w niezbędne leki takie jak środki przeciwbólowe czy węgiel aktywny.",
        "13. Przed wyjazdem sprawdź stan techniczny swojego pojazdu.",
        "14. Jeśli wyjeżdżasz w ziemie, nawet gdy na miejscu jest lato, jedź na zimowych oponach.",
        "15. Zawsze miej w samochodzie butelkę oleju silnikowego dedykowanego do twojego pojazdu.",
        "16. Trudna droga dojazdowa zazwyczaj kryje na końcu wspaniała dziką miejscówkę.",
        "17. Dbaj i myśl o innych, jeśli parkujesz miedzy innymi kamperami, zachowaj odpowiedni odstęp.",
        "18. Jeśli wychodzisz późnym popołudniem na spacer, zabieraj ze sobą latarkę lub powerbenka z kablem do telefonu.",
        "19. Jeśli pomylisz drogę, nie zawracaj, daj się ponieść przygodzie, ale oczywiście z rozwagą.",
        "20. Jeśli wjeżdżasz pod górę na drugim biegu, powianeś zjeżdżać z góry również na drugim biegu.",
        "21. Jeśli podróżujesz sam, udostępniaj często swoją lokalizację najbliższej rodzinie.",
        "22. Jeśli masz możliwość uzupełnić wodę, wylać szarą, czarną wodę, zrób to. Może się okazać że najbliższy serwis będzie nie po drodze.",
        "23. Jeśli podróżujesz z drugą osobą, zawsze ustalcie między sobą sposób komunikacji na wypadek zgubienia się czy rozdzielenia.",
        "24. Jeśli w pobliżu nie ma kosza, śmieci zabieraj ze sobą.",
        "25. Długi wąż do zatankowania wody jest zawsze lepszy niż krótki.",
        "26. Warto zaopatrzyć się w różne końcówki nakręcane na zawory z woda, nigdy nie wiesz co zastaniesz na miejscu.",
        "27. Droga na miejsce do spania była z górki? Sprawdź pogodę, jeśli ma padać zmień miejsce na inne, rano możesz mieć problem z wyjazdem.",
        "28. Nigdy nie zatrzymuj się gdy ktoś do ciebie macha czy to na zwykłej drodze czy autostradzie.",
        "29. Oszczędzaj wodę, gaz i prąd.",
        "30. Pakując się na długi wyjazd nie zabieraj ze sobą niepotrzebnych rzeczy. Z czasem zauważysz że w ogóle Ci ich nie brakuje.",
        "31. Jeśli znalazłeś super miejscówkę na google maps lub park4night sprawdź czy obok niej są inne ciekawe miejsca. Może się okazać że to miejsce nie będzie już dostępne",
        "32. Jeśli dotarłxś na miejsce i nie czujesz się tam bezpiecznie, zmień miejsce na inne.",
        "33. Jeśli nie czujesz się bezpiecznie w okolicy w której akurat jesteś, rozglądaj się za innymi kamperami, w grupie będzie bezpieczniej",
        "34. Znajdź w swoim aucie miejsce na cenne rzeczy, możesz zainstalować mały sejf lub metalową zamykaną skrzynkę. Pamiętaj by odpowiednio ją zabezpieczyć przed kradzieżą.",
        "35. Dbaj o środowisko, w którym podróżujesz. Przestrzegaj zasad ekologicznych, takich jak pozostawianie miejsca czystym i segreguj śmieci.",
        "36. Ciesz się wolnością i przygodą, którą oferuje van life. Niech podróż stanie się dla Ciebie niesamowitą przygodą i doświadczeniem, które na zawsze pozostaną w Twojej pamięci. Żyj tą chwilą!",
        "37. Pamiętaj o poszanowaniu lokalnych kultur i tradycji.",
        "38. Przestrzegaj przepisów drogowych w kraju, przez który podróżujesz. Unikniesz mandatu.",
        "39. Ogranicz korzystanie z plastikowych jednorazowych przedmiotów, takich jak kubki czy sztućce.",
        "40. Przy długiej podróży rób krótkie przystanki na rozprostowanie, możesz również zmieniać pozycję fotela, to da ulgę twojemu kręgosłupowi.",
        "41. Bądź elastyczny i otwarty na zmiany planów, ponieważ w podróży zawsze może pojawić się coś nieprzewidywalnego.",
        "42. Przygotuj się na brak zasięgu telefonu lub internetu w niektórych miejscach.",
        "43. Pamiętaj, aby wypocząć i zrelaksować się, a nie tylko podróżować non-stop.",
        "44. Przed podróżą do danego kraju, pobierz mapy offline nie tylko kraju docelowego ale też te przez które będziesz przejeżdżać.",
        "45. Zainstaluj odpowiednie aplikacje do znalezienia miejsc do spania (GoogleMaps, Park4Night itp)",
        "46. Zawsze miej przy sobie wystarczającą ilość gotówki lub karty płatnicze, aby móc zapłacić za wydatki podróżne.",
        "47. Wiekszą sumę gotówki podziel na kilka mniejszych i schowaj w nieoczyswitych miejscach. Schowek samochodowy to pierwsza rzecz którą sprawdzi potencjalny złodziej.",
        "48. Daj dobry przykład. Jeśli widzisz śmieci pozostawione przez innych, zbierz je i wyrzucić w odpowiednim miejscu.",
        "49. Kup ubezpieczenie podróżne, assistance, holowanie.",
        "50. Dbaj o bezpieczeństwo swoje i swoich bliskich.",
        "51. Korzystaj z możliwości spotkania nowych ludzi i doświadczania różnych kultur.",
        "52. Bądź gotowy na nieprzewidziane wydatki, takie jak naprawa samochodu lub zakup dodatkowego paliwa.",
        "53. W przypadku braku pomysłu na miejsce do zatrzymania na noc, możesz zapytać o możliwość postoju np na stacji benzynowej.",
        "54. Przygotuj się na różne warunki drogowe, takie jak kamieniste drogi, wysokie góry czy drogi z ostrymi zakrętami.",
        "55. Przestrzegaj zasad dotyczących wjazdu do parków narodowych lub innych obszarów chronionych, aby nie narażać przyrody na szkody, a siebie na dodatkowe wydatki.",
        "56. Bądź cierpliwy, gdy jadąc samochodem napotkasz trudne drogi, natłok ludzi lub problemy z samochodem, które mogą spowodować opóźnienia w podróży.",
        "57. Pamiątki. Pamiętaj by zostawić trochę miejsca na rzeczy zakupione w podróży.",
        "58. Odkrywaj nie tylko nowe miejsca, spróbuj także lokalnej kuchni. Otwórz się na nowe smaki, być może z podróży wrócisz z nowym ulubionym daniem.",
        "59. Przestrzegaj zasad dotyczących kempingu, takich jak pozostawianie miejsca w stanie, w jakim je zastaliśmy oraz przestrzeganie zasad dotyczących ognisk i grillowania.",
        "60. Unikaj zanieczyszczenia środowiska, spróbuj stosować ekologiczne kosmetyki i płyny.",
        "61. Możesz zminimalizować zużycie wody, korzystając z publicznych źródeł, w tym toalet i pryszniców.",
        "62. Spróbuj nauczyć się nowych umiejętności, takich jak gotowanie na ognisku, wspinaczka czy surfowanie, aby poszerzyć swoje horyzonty i czerpać więcej radości z podróży.",
        "63. Małe miasteczka lub wioski w okolicy w której obecnie przebywasz mogą być dla ciebie lepszą atrakcją niż zatłoczone turystyczne miasto.",
        "64. Warto zawsze mieć w aucie podstawowe produkty spożywcze takie jak mąka, drożdże, cukier, sól.",
        "65. Ucz się na błędach i nie przestawaj eksperymentować z różnymi rozwiązaniami.",
        "66. Pamiętaj o wykorzystywaniu czasu wolnego do rozwoju swoich zainteresowań i pasji, czy to poprzez czytanie, naukę języków obcych czy tworzenie sztuki.",
        "67. Ciesz się naturą i pozwól sobie na chwile refleksji i medytacji, aby zyskać nowe perspektywy na swoje życie i cele.",
        "68. Bądź gotowy na niespodziewane wyzwania i sytuacje, a także na to, że nie zawsze będzie łatwo.",
        "69. Jeśli podróżujesz sam/sama, pozostań trzeźwy, nie wiesz czy nie przyjedzie Policja i nakaże przeparkowania samochodu.",
        "70. Nie wchodź w dyskusję z lokalną policją i mieszkańcami. Uszanuj ich.",
        "71. Bądź wdzięczny za każdą chwilę i każde doświadczenie, które spotkają Cię na Twojej drodze, a także za każdą osobę, która pojawi się w Twoim życiu i podzieli się z Tobą swoimi historiami i mądrościami.",
        "72. Pamiętaj, że podróżowanie samochodem wiąże się z pewnym ryzykiem, więc zawsze bądź czujny i ostrożny na drodze.",
        "73. Dbaj o swoje relacje z rodziną i przyjaciółmi, utrzymując z nimi kontakt i dzieląc się swoimi doświadczeniami.",
        "74. Bądź otwarty na naukę i rozwój osobisty, wykorzystując czas spędzony w samochodzie na słuchanie audiobooków, podcastów czy ucząc się nowych umiejętności.",
        "75. Uważaj na kieszonkowców w komunikacji miejskiej. Miej zawsze oko na swój bagaż.",
        "76. Jeśli podróżujesz ze zwierzakiem zadbaj o to by miał odpowiednią temperaturę i dostęp do wody pitnej.",
        "77. Zamień chemiczne środki do toalety, ekologicznymi np saszetki lub tabletki do szamb.",
        "78. Nie zostawiaj na noc sprzętu turystycznego (Krzesełek, stolika, grilla) na zewnątrz.",
        "79. Bądź pokorny/a wobec miejscowych i wszystkich przechodniów. Uśmiechnij się! Jesteś częścią ich codziennej rutyny, ich miejsca i domowych terenów.",
        "80. Bądź życzliwy dla miejscowych. Istnieje prawdopodobieństwo, że będziesz potrzebował/a ich pomocy, jeśli będziesz miał/a niespodziewany problem.",
        "81. Dron to wspaniałe urządzenie do tworzenia pamiątek z podróży. Pamiętaj by zachować bezpieczeństwo i prywatność innych ludzi.",
        "82. Jeśli masz drona, sprawdź obowiązujące przepisy w kraju w którym jesteś. Przestrzegaj zakazów lotu w wydzielonych strefach.",
        "83. Jeśli masz drona, nigdy nie startuj blisko lotniska.",
        "84. Nie zasłaniaj swoim autem, widoku z czyjegoś domu, restauracji czy tarasu.",
        "85. Jeśli Twój van / samochód kempingowy zajmuje więcej niż jedno miejsce parkingowe, zaparkujcie w innym miejscu.",
        "86. Czytaj lub tłumacz informacje na znakach.",
        "87. Czasami znalezienie miejsca parkingowego może być problemem. Możesz zapytać miejscowych lub policję o wskazanie dogodnego miejsca na nocleg.",
        "88. Zacznij pisać dziennik z podróży, może to być świetna pamiątka.",
        "89. Zabierz ze sobą grę planszową lub karty, urozmaici to czas podczas złej pogody.",
        "90. Zaplanuj zakupy, taknowanie wody, opróżnienie toalety i szarej wody dzień wcześniej.",
        "91. Weź pod uwagę, że gotowanie w kamperze/campervanie zajmuje znacznie więcej czasu niż w mieszkaniu.",
        "92. Przygotuj się na częste sprzątanie auta. Zaopatrz się w zmiotkę lub odkurzacz.",
        "93. Przygotuj się na liczne owady, nie tylko komary. Moskitiera może być tylko częściowym rozwiązaniem.",
        "94. Nie zapalaj wieczorem światła przy uchylonych drzwiach.",
        "95. Przed wyjazdem sprawdź w jakim stanie jest twoje koło zapasowe, możesz również zaopatrzyć się w zestaw do naprawy opony. Pozwoli to dojechać do najbliższej wulkanizacji.",
        "96. Bądź gotowy wyjść ze swojej strefy komfortu.",
        "97. Jeśli pracujesz zdalnie, zadbaj o wygodne miejsce do pracy. Leżak i plaża fajnie wygląda tylko na zdjęciach.",
        "98. Każdy dzień to przygoda. Traktuj to jako dobrą zabawę.",
        "99. Jeśli podróżujesz ze zwierzakiem, trzymaj go blisko swojego auta.",
        "100. Gdy braknie zasięgu w telefonie, warto mieć ze sobą papierową mapę.",
        "101. Warunki pogodowe podczas spaceru mogą się nagle zmienić.Wsrto mieć ze sobą płaszcz przeciwdeszczowy,który zmieścisz w kieszeni.",
        "102. Przed podróżą sprawdż ważność paszportu i innych dokumentów.",
        "103. Wyrób Europejska Karta Ubezpieczenia Zdrowotnego (EKUZ).",
        "104. Zaopatrz się w mały czajnik do zagotowania wody na kawę zaoszczędzisz czas i wodę.",
        "105. Pamiętaj o kremie z filtrem UV, latem, zimą a nawet jak idziesz w góry.",
        "106. Rób listę zakupoów. Unikniesz niepotrzebnych/dodatkowych wydatków.",
        "107. Nie pakuj się na ostatnią chwile, naszykuj potrzebne rzeczy, przynajmniej dwa dni wcześniej.",
        "108. Butelka alkoholu lub inny prezent to dobry pomysł by wręczyć w podzięce za pomoc.",
        "109. Jeśli jesteś blisko stacji paliw i świeci się rezerwa, zatankuj, bo kolejna stacja może być za daleko.",
        "110. Dziel się swoimi doświadczeniami z innymi.",
        "111. Gdy jest okazja na zatankowanie wody lub opróżnienie toalety, zrób to, podobnie jak w przypadku paliwa, nigdy nie wiesz kiedy będzie kolejna szansa.",
        "112. Jeśli podróżujesz z kimś, szczególnie w krajach po za UE, warto ustalic sposób komunikacji w sytuacji braku internetu.",
        "113. Jeśli masz złe przeczucia odnośnie stanu swojego pojazdu nie ignoruj go.",
        "114. Przy naprawie samochodu zaczynaj od najdroższych rzeczy, jeśli planujesz naprawy w tańszym kraju pamiętaj może Cię to kosztować dwa razy więcej.",
        "115. Kiedy masz złe przeczucia co do miejsca w którym zamierzasz nocować, znajdz inne, po co kusić los.",
        "116. Nie odkładaj sniadania na później, w ciągu dnia wiele się dzieje a pierwszy posiłek o 19 nazywany zwykle jest kolacja.",
        "117. Jeśli czas nie pokrywa się z kilometrami rozważ zmianę miejscowki, może to oznaczać drogę bardzo słabej jakości lub offroad.",
        "118. Jeśli mapy Google źle wskazują drogę, warto sprawdzić ją w innej aplikacji.",
        "119. Jeśli coś się zepsuło i nagle się samo naprawiło to znaczy że nadal jest zepsute",
        "120. Teytytki szara taśma i WD 40 miej zawsze w pogotowiu",
        "121. Gdy wczorajszego wieczoru impreza się przedłużyła, odczekaj zanim wsiądziesz za kierownice lub udaj się na komisariat Policji i poproś o badanie alkomatem.",
        "122. Jeśli jesteś w górach i spadł śnieg, poczekaj aż pojawi się pług śniezny. Jedź za nim, to znacznie ułatwi drogę.",
        "123. Jeżeli gdzieś wyjeżdzasz, zawsze bierz ze sobą paszport, nigdy nie wiesz gdzie cię poniesie przygoda.",
        "124. Zapoznaj się z zasadami ruchu drogowego i kulturą jazdy tamtejszych kierowców",
        "125. Sprawdź jakie jesy obowiązkowe wyposażenie samochodu w kraju do którego jedziesz, a także przez jakie przejeżdżasz. (kamizelki, gaśnica, trójkąt)",
        "126. Pamiętaj o zabraniu zielonej karty gdy wyjedzasz autem za granice.",
        "127. Jeśli to możliwe wykup dodatkowe ubezpieczenie obowiązujące w kraju do którego jedziesz.",
        "128. Jeśli planujesz wyjazd po za Unię Europejską sprawdź wymagania w danym kraju.",
        "129. Sprawdź czy w kraju do którego wyjezdzasz są obowiązkowe szczepienia.",
        "130. Zapytaj lokalnych mieszkanscow o atrakcje w okolicy",
        "131. zapoznaj sie z kultura w danym kraju np gesty.",
        "132. Zawsze zapinj pasy bezpieczeństwa, mogą uroatować Ci zycie.",
        "133. Unikaj jazdy po alkoholu, nawet po jednym piwie."
    ]

    let RulesListES = [
        "1. Invierte en un buen colchón: dormir es muy importante para tu salud y bienestar.",
        "2. Es una buena idea tener un juego básico de herramientas en tu coche: incluso si no puedes arreglar tu coche tú mismo, alguien puede ayudarte.",
        "3. Prepara una lista de cosas que necesitas llevar contigo antes de cada viaje.",
        "4. Siempre lleva un botiquín de primeros auxilios contigo.",
        "5. Planea tus viajes con antelación y presta atención a las condiciones climáticas.",
        "6. Aprende a usar diferentes fuentes de energía, desde paneles solares hasta un generador.",
        "7. Siempre lleva suficiente agua potable contigo.",
        "8. Prueba todo el equipo de tu camper o remolque antes de tu primer viaje.",
        "9. Aprende cómo funciona el sistema de drenaje y cómo mantener la higiene.",
        "10. Siempre cierra las puertas y ventanas cuando salgas del camper o remolque.",
        "11. Recuerda realizar el mantenimiento y las inspecciones de tu camper o remolque con regularidad.",
        "12. Abastécete de medicamentos necesarios, como analgésicos y carbón activado.",
        "13. Revisa el estado técnico de tu vehículo antes de salir.",
        "14. Si te diriges al campo, incluso cuando sea verano en el suelo, conduce con neumáticos de invierno.",
        "15. Siempre lleva una botella de aceite de motor específica para tu vehículo en tu coche.",
        "16. Un camino difícil de acceso suele ocultar un gran lugar salvaje al final.",
        "17. Sé considerado y piensa en los demás. Si estacionas entre otros campers, mantén una distancia adecuada.",
        "18. Si sales a caminar al atardecer, lleva una linterna o un powerbank con un cable para tu teléfono.",
        "19. Si te confundes en el camino, no des la vuelta, déjate llevar por la aventura, pero con precaución.",
        "20. Si subes una colina en segunda marcha, también deberías bajarla en segunda marcha.",
        "21. Si viajas solo, comparte tu ubicación frecuentemente con tus familiares cercanos.",
        "22. Si tienes la oportunidad de rellenar agua o vaciar las aguas grises y negras, hazlo. Puede que el centro de servicio más cercano no esté en tu ruta.",
        "23. Si viajas con otra persona, establece siempre una forma de comunicación en caso de que se pierdan o separen.",
        "24. Lleva tu basura contigo si no hay un contenedor de basura cercano.",
        "25. Una manguera larga para llenar agua siempre es mejor que una corta.",
        "26. Es una buena idea tener una variedad de adaptadores para válvulas de agua; nunca sabes qué encontrarás en el sitio.",
        "27. ¿El camino al lugar para dormir era cuesta abajo? Revisa el clima, si se espera lluvia cambia a otro lugar, por la mañana podrías tener problemas para salir.",
        "28. Nunca te detengas si alguien te hace señas en una carretera normal o en la autopista.",
        "29. Ahorra dinero, agua, gas y electricidad.",
        "30. El minimalismo es tu amigo. Al empacar para un viaje largo, no lleves cosas innecesarias. Con el tiempo notarás que no las extrañas en absoluto.",
        "31. Planificación. Si has encontrado un lugar genial en Google Maps o Park4Night, verifica si hay otros lugares interesantes cerca. Puede que el lugar ya no esté disponible para pernoctar.",
        "32. Seguridad. Si llegas a un lugar y no te sientes seguro, cámbialo por otro.",
        "33. En grupo es mejor. Si no te sientes seguro en la zona en la que te encuentras, busca otros campers, será más seguro estar con más campers.",
        "34. Tesoros. Encuentra un lugar en tu coche para tus objetos de valor. Puedes instalar una pequeña caja fuerte o una caja metálica con cerradura. Recuerda asegurarlo adecuadamente contra robos.",
        "35. Respeta el medio ambiente: Cuida el entorno en el que viajas. Sigue las normas ambientales, como dejar el lugar limpio y separar la basura.",
        "36. Disfruta de tu libertad: Goza de la libertad y la aventura que ofrece la vida en camper. Haz de tu viaje una experiencia inolvidable. ¡Vive este momento!",
        "37. Cultura y tradición. Recuerda respetar las culturas y tradiciones locales.",
        "38. Respeta las leyes de tránsito del país por el que viajas. Evita multas.",
        "39. Limita tu uso de artículos desechables de plástico.",
        "40. En viajes largos, haz paradas cortas para estirarte. También puedes cambiar la posición de tu asiento; esto aliviará tu columna vertebral.",
        "41. Sé flexible y abierto a cambios en los planes, ya que siempre puede surgir algo inesperado al viajar.",
        "42. Prepárate para la falta de cobertura de teléfono o internet en algunos lugares.",
        "43. Recuerda descansar y relajarte, no solo viajar sin parar.",
        "44. Antes de viajar a un país, descarga mapas offline no solo del país de destino sino también de los que atravesarás.",
        "45. Instala aplicaciones adecuadas para encontrar lugares donde dormir (Google Maps, Park4Night, etc.).",
        "46. Lleva siempre suficiente efectivo o una tarjeta de débito para pagar los gastos de viaje.",
        "47. Divide grandes cantidades de efectivo en varias más pequeñas y escóndelas en lugares discretos. La guantera del coche es lo primero que revisará un posible ladrón.",
        "48. Da un buen ejemplo. Si ves basura dejada por otros, intenta recogerla y desecharla en un lugar adecuado.",
        "49. Contrata un seguro de viaje, asistencia, remolque.",
        "50. Cuida tu seguridad y la de tus seres queridos. Siempre usa el cinturón de seguridad y evita conducir después de beber alcohol.",
        "51. Lleva una copia física de los documentos importantes como el pasaporte, licencia de conducir y seguro de viaje.",
            "52. Si viajas en invierno, lleva cadenas para la nieve y verifica que tu vehículo esté preparado para temperaturas bajas.",
            "53. Aprende algunas palabras básicas en el idioma del lugar al que viajas. Podría ser útil en caso de emergencia.",
            "54. Nunca dejes objetos de valor a la vista dentro de tu vehículo.",
            "55. Lleva contigo un cargador solar para tus dispositivos en caso de que te quedes sin batería.",
            "56. Si viajas con niños, asegúrate de que tengan entretenimiento adecuado para viajes largos.",
            "57. Mantén una rutina de limpieza dentro de tu camper para evitar el desorden.",
            "58. Lleva un mapa físico además de las aplicaciones en línea, ya que en algunas áreas podrías quedarte sin conexión.",
            "59. Aprende cómo realizar reparaciones básicas en tu vehículo.",
            "60. Respeta las áreas privadas y estaciona solo en lugares permitidos.",
            "61. Lleva una linterna potente y pilas de repuesto.",
            "62. Siempre verifica los horarios y regulaciones locales antes de estacionarte o acampar.",
            "63. Lleva ropa adecuada para cambios bruscos de clima.",
            "64. Si viajas con mascotas, asegúrate de llevar su comida, agua y accesorios necesarios.",
            "65. Aprende técnicas básicas de primeros auxilios.",
            "66. Nunca confíes completamente en los sistemas GPS, siempre verifica las rutas por tu cuenta.",
            "67. Sé respetuoso con la fauna local y evita alimentarla o interactuar en exceso.",
            "68. Asegúrate de llevar una buena silla plegable para relajarte al aire libre.",
            "69. Investiga sobre los lugares de interés cercanos para enriquecer tu experiencia de viaje.",
            "70. Comparte tus experiencias de viaje con otros viajeros; podrías aprender consejos útiles.",
            "71. Mantén una actitud positiva y flexible ante contratiempos.",
            "72. Lleva contigo un diario de viaje para registrar tus aventuras.",
            "73. Si encuentras un lugar espectacular, tómate el tiempo para disfrutarlo plenamente en lugar de apresurarte a seguir.",
            "74. Mantén la calma si enfrentas problemas mecánicos y busca ayuda profesional si es necesario.",
            "75. Aprovecha las redes sociales para conectar con otros viajeros y compartir recomendaciones.",
            "76. Antes de partir, revisa los frenos, luces y niveles de fluidos de tu vehículo.",
            "77. Lleva contigo repelente de insectos si planeas estar en áreas al aire libre por mucho tiempo.",
            "78. Familiarízate con las reglas de tráfico locales y respétalas siempre.",
            "79. Planifica paradas regulares para descansar y evitar la fatiga del conductor.",
        "80. Sé amable con los locales. Es probable que necesites su ayuda si tienes un problema inesperado.",
            "81. Un dron es un gran dispositivo para crear recuerdos de viaje. Recuerda respetar la seguridad y la privacidad de otras personas.",
            "82. Si tienes un dron, verifica las regulaciones actuales en el país en el que te encuentras. Respeta las prohibiciones de vuelo en áreas designadas.",
            "83. Si tienes un dron, nunca despegues cerca de un aeropuerto.",
            "84. No obstruyas la vista desde la casa, restaurante o terraza de alguien.",
            "85. Si tu furgoneta/autocaravana ocupa más de un espacio de estacionamiento, estaciona en otro lugar.",
            "86. Lee/traduce la información en los letreros.",
            "87. A veces encontrar un lugar de estacionamiento puede ser un problema. Puedes preguntar a los locales o a la policía por un lugar conveniente para quedarte.",
            "88. Comienza a escribir un diario de viaje, puede ser un gran recuerdo.",
            "89. Lleva un juego de mesa o cartas contigo, añadirá variedad a tu tiempo durante el mal tiempo.",
            "90. Aborda cada día estratégicamente. Planifica las compras, el mantenimiento, el vaciado del inodoro y el agua gris el día anterior.",
            "91. Cocinar en una caravana/autocaravana lleva mucho más tiempo que en una sartén rápida.",
            "92. Prepárate para limpiar el coche con frecuencia. Abastécete de una escoba o aspiradora.",
            "93. Prepárate para numerosos insectos, no solo mosquitos. Una mosquitera puede ser solo una solución parcial.",
            "94. No enciendas una luz por la noche con la puerta entreabierta.",
            "95. Antes de salir, verifica el estado de tu rueda de repuesto, también puedes obtener un kit de reparación de neumáticos. Esto te permitirá llegar al vulcanizador más cercano.",
            "96. Prepárate para salir de tu zona de confort.",
            "97. Si trabajas de forma remota, asegúrate de tener un lugar cómodo para trabajar. Una tumbona y una playa se ven bien solo en las fotos.",
            "98. Cada día es una aventura. Trátalo como un buen momento.",
            "99. Si viajas con una mascota, mantenla cerca de tu coche.",
            "100. Cuando no haya cobertura en tu teléfono, es una buena idea tener un mapa de papel contigo.",
            "101. Las condiciones climáticas durante una caminata pueden cambiar repentinamente, es aconsejable llevar un impermeable que pueda caber en tu bolsillo.",
            "102. Antes de viajar, verifica la vigencia de tu pasaporte y otros documentos.",
            "103. Obtén una Tarjeta Sanitaria Europea (EHIC).",
            "104. Lleva un hervidor pequeño para hervir agua para café y ahorrar tiempo y agua.",
            "105. Recuerda el protector solar UV, en verano, invierno e incluso cuando vayas a las montañas.",
            "106. Haz una lista de compras para evitar gastos innecesarios/adicionales.",
            "107. No empaques en el último minuto, prepara los artículos necesarios al menos dos días antes.",
            "108. Una botella de alcohol u otro regalo es una buena idea como agradecimiento por la ayuda." ]

func getLocalizedRules() -> [String] {
    switch LanguageManager.shared.currentLanguage {
    case .english, .system:
        return RulesList
    case .polish:
        return RulesListPL
    case .spanish:
        return RulesListES
    }
}
