function tset = load_training_set()
getuserinfo; % which computer am I on
cd([githubdirectory 'Spike2Scripts\Cell_Identifier\training_set\']);

tsetls = ls;
tsetls = tsetls(3:end,:);
[nofiles, ~] = size(tsetls);
tset = cell(nofiles,1);
c = 1;
for a = 1:nofiles
    cur = load(tsetls(a,:));
    names = fieldnames(cur);
    [noclus, ~] = size(names);
    for b = 1:noclus
        if isa(eval(['cur.',names{b}]),'unit')
            eval(['tset{', num2str(c),'}= cur.', names{b},';']);
            c = c+1;
        end
    end        
end
end