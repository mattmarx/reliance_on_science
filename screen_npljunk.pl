#!/usr/bin/perl

while (<>) {
$junk = 0;
$junk = 1 if /inter partes/;
$junk = 1 if /claim chart/;
$junk = 1 if /supplemental joint .*validity contentions/;
$junk = 1 if /claims of the/;
$junk = 1 if /petition in opposition/;
$junk = 1 if /declaration of/;
$junk = 1 if /transmittal letter/;
$junk = 1 if /english language abstract of/;
$junk = 1 if /united states patent/;
$junk = 1 if /photographs of/;
$junk = 1 if /owner's manual/;
$junk = 1 if /installation instructions/;
$junk = 1 if /installation and operation/;
$junk = 1 if /showing prior art/;
$junk = 1 if /examination report/;
$junk = 1 if /international standard/;
$junk = 1 if /letter to judge/;
$junk = 1 if /english abstract/;
$junk = 1 if /patent office/;
#$junk = 1 if /ietf/;
$junk = 1 if /patent abstract/;
$junk = 1 if /patent application/;
$junk = 1 if /appl. no. /;
$junk = 1 if /patent pending/;
$junk = 1 if /application no/;
$junk = 1 if /written opinion/;
$junk = 1 if /brochure/;
$junk = 1 if /office action/;
$junk = 1 if /patent search/;
$junk = 1 if / search report/;
$junk = 1 if /advertisement that/;
$junk = 1 if /price list/;
$junk = 1 if /wikipedia.org/;
$junk = 1 if /web documents/;
$junk = 1 if /patent office/;
$junk = 1 if /notification of reasons for refusal/;
$junk = 1 if / exhibit \d+/;
$junk = 1 if /japanese abstract/;
$junk = 1 if /machine translation of jp /;
$junk = 1 if / with website update /;
$junk = 1 if / as seen on .* \.com/;
$junk = 1 if / as seen at .*\.com/;
$junk = 1 if / showing web update /;
$junk = 1 if /definition of .* from .* dictionary/;
$junk = 1 if /notice of sealing.*patent/;
$junk = 1 if /business wire/;
$junk = 1 if /newswire/;
$junk = 1 if /report of novelty search/;
$junk = 1 if /application serial no./;
$junk = 1 if /technical disclosure bulletin/;
$junk = 1 if /datasheet/;
$junk = 1 if /written request for the invalidation/;
$junk = 1 if /fda public health notification/;
$junk = 1 if /newsletter/;
$junk = 1 if /home page .* http/;
$junk = 1 if /retrieved from .*url/;
$junk = 1 if /search.proquest/;
$junk = 1 if /retrieved from the internet/;
$junk = 1 if /quick reference/;
$junk = 1 if /user guide/;
$junk = 1 if /system guide/;
$junk = 1 if /setup guide/;
$junk = 1 if /product data ?sheet/;
$junk = 1 if /technical specification group/;
$junk = 1 if /posted at youtube/;
$junk = 1 if /located on the internet/;
$junk = 1 if /quick guide/;
$junk = 1 if /accelerated examination support document/;
$junk = 1 if /application of .* fed\. cir\./;
$junk = 1 if /quick start guide/;
$junk = 1 if /developer guide.*version/;
$junk = 1 if /definition of .* dictionary/;
$junk = 1 if /product catalog/;
$junk = 1 if /google plus users/;
$junk = 1 if /report on patentability/;
$junk = 1 if /product catalog/;
$junk = 1 if /notice of allowance/;
$junk = 1 if /wikipedia.*free encyclopedia/;
$junk = 1 if /search report of .*counterpart application/;
$junk = 1 if /reference manual/;
$junk = 1 if /granting motion to correct/;
$junk = 1 if /prior art chart/;
$junk = 1 if /draft standard/;
$junk = 1 if /webster dictionary/;
$junk = 1 if /motion to strike/;
$junk = 1 if /invalidity chart/;
$junk = 1 if /draft standard/;
$junk = 1 if /request for comment/;
$junk = 1 if /readme/;
$junk = 1 if /expert opinion/;
$junk = 1 if /declaration of/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
$junk = 1 if /xxxxxxxxxxxxxxxxxxx/;
print if $junk==0;

}