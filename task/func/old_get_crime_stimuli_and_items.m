function [places, characters, weapons, character_items, weapon_items, place_items] = get_crime_stimuli_and_items()


places.png     = {'Park.png', 'Einkaufszentrum.png', 'Bushaltestelle.png', 'WohnortDesOpfers.png'};
places.text    = {'im Park', 'im Einkaufszentrum', 'an der Bushaltestelle', 'am Wohnort des Opfers'};
places.con     = {'park', 'mall', 'bus_stop', 'house'};
characters.png = {'Blau.png', 'Gelb.png', 'Grün.png', 'Pink.png'};
characters.text= {'blau', 'gelb', 'grün', 'pink'};
characters.con = {'blue', 'yellow', 'green', 'pink'};
weapons.png    = {'Baseball.png', 'Gift.png', 'Kaktus.png', 'Kerzenstaender.png'};
weapons.text   = {'ein Baseballschläger', 'Gift', 'ein Kaktus', 'ein Kerzenständer'};
weapons.con    = {'baseball_bat', 'poison', 'cactus', 'candlestick'};


character_items = ...
{'Der Täter war in # gekleidet.',
'Der Täter hatte etwas in # an.',
'Die Kleidung des Täters war #.',
'Der Mörder trug etwas in #.',
'Hatte der Täter Kleidung in der Farbe # an?',
'War der Täter in # gekleidet?',
'Die Person in # ist schuldig.',
'Die Person mit Kleidung in # war der Täter.'};

weapon_items = ...
{'War die Tatwaffe #?',
'Die Tatwaffe könnte # gewesen sein.',
'Es wurde # benutzt, um das Opfer zu ermorden.',
'Es wurde # benutzt, um dem Opfer Schaden zuzufügen.'};

place_items = ...
{'Warst du zur Tatzeit #?',
'Der Täter war zur Tatzeit #.',
'Die Tat hat # stattgefunden.', 
'Hast du dich zur Tatzeit # aufgehalten?'};
end