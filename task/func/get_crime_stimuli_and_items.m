function [places, characters, weapons, character_items, weapon_items, place_items, luegenitems] = get_crime_stimuli_and_items()


places.png     = {'Park.png', 'Einkaufszentrum.png', 'Bushaltestelle.png', 'WohnortDesOpfers.png'};
places.text    = {'im Park', 'im Einkaufszentrum', 'an der Bushaltestelle', 'am Wohnort des Opfers'};
places.con     = {'park', 'mall', 'bus_stop', 'house'};
characters.png = {'Blau.png', 'Gelb.png', 'Grün.png', 'Pink.png'};
characters.text= {'blau', 'gelb', 'grün', 'pink'};
characters.con = {'blue', 'yellow', 'green', 'pink'};
weapons.png    = {'Baseball.png', 'Gift.png', 'Kaktus.png', 'Kerzenstaender.png'};
weapons.text   = {'einen Baseballschläger', 'Gift', 'einen Kaktus', 'einen Kerzenständer'};
weapons.con    = {'baseball_bat', 'poison', 'cactus', 'candlestick'};


character_items{1} = ...
{'Warst du in # gekleidet?',
'Hattest du etwas in # an?',
'War deine Kleidung #?',
'Hast du die Farbe # getragen?'};

character_items{2} = ...
{'War der Täter in # gekleidet?',
'Hatte der Täter etwas in # an?',
'War die Kleidung des Täters #?',
'Hat der Täter die Farbe # getragen?'};

weapon_items{1} = ...
{'Hast du # benutzt?',
'Hattest du # dabei?',
'Hast du # verwendet?',
'Hast du # gebraucht?'};

weapon_items{2} = ...
{'Hat der Täter # benutzt?',
'Hatte der Täter # dabei?',
'Hat der Täter # verwendet?',
'Hat der Täter # gebraucht?'};

place_items = ...
{'Warst du zur Tatzeit #?',
'Der Täter war zur Tatzeit #.',
'Die Tat hat # stattgefunden.', 
'Hast du dich zur Tatzeit # aufgehalten?'};

tmp = readtable('./stim/luegenitems.txt', 'ReadVariableNames', false);
luegenitems = strcat(tmp.Var1, '?');
end