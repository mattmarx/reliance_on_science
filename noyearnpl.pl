#!/usr/binperl

while (<>) {
 #chomp;
 print if (!/\D18\d\d\D/ && !/\D19\d\d\D/ && !/\D20[01]\d\D/);
}
