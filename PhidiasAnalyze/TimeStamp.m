function s = TimeStamp

tmp = strrep(datestr(clock), ':' , '-' );
s= strrep(tmp, ' ' , '-' );
ii=find(s=='-');
s(ii(4))='h';
s(ii(5))='m';
s=strcat(s, 's'); 

end

