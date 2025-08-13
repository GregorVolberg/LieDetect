function [vp, instruct, responseHand, rkeys, self, instruct_wo_tasten] = get_experimentInfo()
vp = input('\nParticipant (three characters, e.g. S01)?\n', 's');
    if length(vp)~=3 
       error ('Use three characters for the name, e. g. ''S01'''); end

   response_mapping = str2num(input('\nResponse mapping?\n1: left hand, \n2: right hand\n', 's'));    
      if ~ismember(response_mapping, [1, 2])
        error('\nUse only numbers 1 or 2 for the response mapping.'); end
   
    switch response_mapping
    case  1
        instruct1 = 'Antworte mit der linken Hand.\n\n';
        responseHand = 'left';
    case  2
        instruct1 = 'Antworte mit der rechten Hand.\n\n';
        responseHand = 'right';
    end
rkeys = {'y', 'x'};
instr2 = '\n(korrekt)    Y - X    (nicht korrekt)\n\n\nDrücke eine der Antworttasten, um den Durchgang zu starten.\n';
instruct = [instruct1, instr2]; 

instr3 = '\n(korrekt)    Y - X    (nicht korrekt)\n';
instruct_wo_tasten = [instruct1, instr3];

haendigkeit_nr = str2num(input('\nHändigkeit?\n1: Rechtshänder, \n2: Linkshänder\n', 's'));    
      if ~ismember(haendigkeit_nr, [1, 2])
        error('\nUse only numbers 1 or 2 for Händigkeit.'); end
hand_choose = {'Rechtshänder', 'Linkshänder'};
haendigkeit = ['Bist du ', hand_choose{haendigkeit_nr}, '?'];

alter_nr = str2num(input('\nAlter?\n', 's'));
alter = ['Bist du ', num2str(alter_nr), ' Jahre alt?'];

groesse_nr = str2num(input('\nKörpergröße in cm?\n', 's'));
groesse = ['Bist du ', num2str(groesse_nr) ' cm groß?'];

auge_nr     = str2num(input('\nAugenfarbe?\n1: braun, \n2: blau, \n3: grün, \n4: grau\n', 's'));
      if ~ismember(auge_nr, [1, 2, 3, 4])
        error('\nUse only numbers 1 to 4 for Augenfarbe.'); end

auge_choose = {'braun', 'blau', 'grün', 'grau'};
augenfarbe  = ['Hast du ', auge_choose{auge_nr} 'e Augen?'];
self.text   = {haendigkeit, alter, groesse, augenfarbe};
self.con    = {'handeness', 'age', 'body_height', 'eye_color'};
self.pick   = {haendigkeit_nr, alter_nr, groesse_nr, auge_nr};
self.hand_choose = hand_choose;
self.auge_choose = auge_choose; 
end


    

