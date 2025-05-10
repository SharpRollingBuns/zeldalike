% ===============================================================
%  base.lp — компактная и быстрая заготовка под clingo 5.4
%  • рассчитана на карту 35×20, но w/h легко переопределить
%  • оптимизация по сумме длин рёбер (псевдо-MST)
%  • без #acyclic и других конструкций, появившихся после 5.4
% ===============================================================

% ---------- ГЛОБАЛЬНЫЕ КОНСТАНТЫ (можно переопределять из GDScript)
#const w = 35.
#const h = 20.
rooms(8).                % требуемое число «центров»
keys(1).                 % сколько ключей
% seed/1, grid/2, difficulty/1 — произвольные дополнительные факты

% ---------- ОБЛАСТЬ ОПРЕДЕЛЕНИЯ
x(0..w-1).     y(0..h-1).
cell(X,Y)            :- x(X), y(Y).

% ---------- РАСКЛАДКА КЛЕТОК
{ wall(X,Y); floor(X,Y) } = 1 :- cell(X,Y).
#heuristic floor(X,Y). [1,false]       % продвигаем floor

% ---------- ГРАНИЧНЫЕ ДВЕРИ  (без ';' в теле!)
border(0,Y)      :- floor(0,Y),      y(Y).
border(Wm1,Y)    :- floor(Wm1,Y),    y(Y), Wm1 = w-1.
border(X,0)      :- floor(X,0),      x(X).
border(X,Hm1)    :- floor(X,Hm1),    x(X), Hm1 = h-1.

1 { door(X,Y) : border(X,Y) } 2.

% ---------- «ЦЕНТРЫ» КОМНАТ
{ center(X,Y) : floor(X,Y) }.
:- rooms(R), #count{ X,Y : center(X,Y) } != R.
#heuristic center(X,Y). [2,false]

% ---------- ОПРЕДЕЛЯЕМ «УПОРЯДОК» — линейный, значит циклов не будет
ordered(X1,Y1,X2,Y2)      :-
    center(X1,Y1), center(X2,Y2),
    100*X1 + Y1 < 100*X2 + Y2.        % тот же приём, что и раньше

% ---------- ДИСТАНЦИЯ (Манхэттен)
dist(X1,Y1,X2,Y2,D)        :-
    ordered(X1,Y1,X2,Y2),
    D = |X1 - X2| + |Y1 - Y2|.

% ---------- КОРЕНЬ и РОДИТЕЛЬ ДЛЯ КАЖДОГО ЦЕНТРА (дерево без #acyclic)
earlier(X,Y)               :- ordered(Xp,Yp,X,Y).
root(X,Y)                  :- center(X,Y), not earlier(X,Y).

% «у каждого не-root центра ровно ОДИН родитель из более ранних»
1 { chosen(Xp,Yp,Xc,Yc) : ordered(Xp,Yp,Xc,Yc) } 1 :-
    center(Xc,Yc), not root(Xc,Yc).

% ---------- ОПТИМИЗАЦИЯ — минимизируем суммарную длину рёбер
#minimize { D@1,Xp,Yp,Xc,Yc :
            chosen(Xp,Yp,Xc,Yc), dist(Xp,Yp,Xc,Yc,D) }.

#heuristic chosen(Xp,Yp,Xc,Yc)[1@1,false].

% ---------- КЛЮЧИ
{ key(X,Y) : center(X,Y) }.
:- keys(K), #count{ X,Y : key(X,Y) } != K.

% ---------- ЗАМКИ (факты приходит из GDScript)
#external lockpair(A,B,C,D,E) : true.
door(X,Y)                   :- lockpair(_,X,Y,_,_).
door(X,Y)                   :- lockpair(_,_,_,X,Y).

% ---------- СВЯЗНОСТЬ ПОЛОВ
reachable(0,0)              :- floor(0,0).
reachable(X2,Y2)            :-
    reachable(X1,Y1), floor(X2,Y2),
    |X1 - X2| + |Y1 - Y2| = 1.
:- floor(X,Y), not reachable(X,Y).

% ---------- ВЫВОД
#show wall/2.
#show floor/2.
#show door/2.
#show key/2.
#show center/2.
#show chosen/4.   % ← рёбра дерева (при желании скрыть — закомментируйте)
