<?php
	
function BodyHead()
	
{
?>
	<div id ="head">
		<div id="head_logo_left"></div>
		<div id="head_logo_right"></div>

		<div id='name'>Fédération Francaise de ski</div>
		<div id='place'></div>
		<div id='title'>Résultats Officieux</div>
		<div id='mode'>Classement</div>
	</div>
<?php
}

function BodyRanking()
{
	BodyHead();
?>
	<div id="block_ranking">
		<div class="row_label">
			<div class="label_rank">Clt</div>
			<div class="label_bib">Dossard</div>
			<div class="label_identity">Nom - Prénom</div>
			<div class="label_cltc">Cltc.</div>
			<div class="label_categ">Cat.</div>
			<div class="label_sex">S.</div>
			<div class="label_distance">Dist.</div>
			<div class="label_equipe">Club</div>
			<div class="label_time">Temps.</div>
		</div>
		<div class="row1"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row2"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row3"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row4"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row5"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row6"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row7"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row8"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row9"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><<div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row10"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row11"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row12"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row13"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row14"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row15"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row16"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row17"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row18"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row19"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>
		<div class="row20"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="cltc"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div><div class="time"></div></div>

	</div>


	<div id="block_clock_running">
		<div class="hour"></div>
		<div class="time"></div>
	<div>
<?php
}

function BodyRanking2()
{
	BodyHead();
?>
	<div id="block_ranking2">
		<div class="row_label">
			<div class="label_rank">Clt</div>
			<div class="label_bib">Dossard</div>
			<div class="label_identity">Nom - Prénom</div>
			<div class="label_equipe">E.S.F.</div>
			<div class="label_time1">Tps.M1</div>
			<div class="label_rank1">Clt.M1</div>
			<div class="label_time2">Tps.M2</div>
			<div class="label_rank2">Clt.M2</div>
			<div class="label_time">Total</div>
		</div>

		<div class="row1"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row2"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row3"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row4"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row5"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row6"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row7"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row8"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row9"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row10"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row11"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row12"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row13"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row14"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row15"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row16"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row17"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row18"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row19"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row20"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row21"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div  class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row22"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row23"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
		<div class="row24"><div class="rank"></div><div class="bib"></div><div class="identity"></div><div class="team"></div><div class="time1"></div><div class="rank1"></div><div class="time2"></div><div class="rank2"></div><div class="time"></div></div>
	
	</div>

	<div id="block_running">
		<div class="best_identity">best Identity</div>
		<div class="best_time">best Time</div>

		<div class="bib"></div>
		<div class="identity"></div>
		<div class="team"></div>
		<div class="rank"></div>
		<div class="time"></div>
		<div class="diff"></div>
	<div>
<?php
}

function BodyStartlist()
{
	BodyHead();
?>
	<div id="block_start_list">
		<div class="row_label">
			<div class="label_bib">Dossard</div>
			<div class="label_identity">Nom - Prénom</div>
			<div class="label_categ">Cat.</div>
			<div class="label_sex">S.</div>
			<div class="label_distance">Dist.</div>
			<div class="label_team">Equipe</div>
		</div>

		<div class="row1"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row2"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row3"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row4"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row5"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row6"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row7"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row8"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row9"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row10"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row11"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row12"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row13"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
		<div class="row14"><div  class="bib"></div><div class="identity"></div><div class="team"></div><div class="categ"></div><div class="sex"></div><div class="distance"></div></div>
	</div>
	
	
<?php
}

function BodyClear()
{
?>
	<div id="block_clear">
	</div>
<?php
}
?>
