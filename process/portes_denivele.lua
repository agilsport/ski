------------------------------------------------------------
--  Controle du nombre de portes via Portes_Denivele
--  Version 100% compatible skiFFS
--  Les paramètres sont fournis dans un tableau Lua :
--      params.code_saison
--      params.code_activite
--      params.code_discipline
--      params.code_entite
--      params.categ
--      params.sexe
--      params.denivele
--      params.nb_portes
--
--  Le script utilise l'objet "base" fourni par skiFFS :
--      base:GetTable()
--      base:TableLoad()
------------------------------------------------------------

------------------------------------------------------------
-- 1. Construction de la requête SQL
------------------------------------------------------------
local function build_query(p)
    return string.format([[
        SELECT Mini, Maxi, Plus_moins
        FROM Portes_Denivele
        WHERE Code_saison   = '%s'
          AND Code_activite = '%s'
          AND Code_discipline = '%s'
          AND Code_entite   = '%s'
          AND Categ         = '%s'
          AND Sexe          = '%s'
          AND Denivele      = %d
    ]],
        p.code_saison,
        p.code_activite,
        p.code_discipline,
        p.code_entite,
        p.categ,
        p.sexe,
        tonumber(p.denivele)
    )
end

------------------------------------------------------------
-- 2. Lecture des règles dans Portes_Denivele
------------------------------------------------------------
local function get_gate_rules(p)
    local tbl = base:GetTable("Portes_Denivele")
    local sql = build_query(p)

    -- Charge le résultat dans la table Lua
    base:TableLoad(tbl, sql)

    -- Si aucune ligne → erreur
    if #tbl == 0 then
        return nil
    end

    -- On prend la première (il ne doit y en avoir qu'une)
    local row = tbl[1]

    return {
        Mini       = tonumber(row.Mini),
        Maxi       = row.Maxi ~= nil and tonumber(row.Maxi) or nil,
        Plus_moins = tonumber(row.Plus_moins)
    }
end

------------------------------------------------------------
-- 3. Contrôle du nombre de portes
------------------------------------------------------------
local function check_gates(p)
    local rules = get_gate_rules(p)

    if not rules then
        return false, "Aucune règle trouvée dans Portes_Denivele pour ces paramètres."
    end

    local mini = rules.Mini
    local maxi = rules.Maxi
    local nb   = tonumber(p.nb_portes)

    -- Vérification Mini
    if nb < mini then
        return false, string.format(
            "ERREUR : %d portes < Mini (%d) pour %s %s (Categ=%s, Sexe=%s, VD=%d)",
            nb, mini,
            p.code_discipline, p.code_entite,
            p.categ, p.sexe, p.denivele
        )
    end

    -- Vérification Maxi (si existe)
    if maxi ~= nil and nb > maxi then
        return false, string.format(
            "ERREUR : %d portes > Maxi (%d) pour %s %s (Categ=%s, Sexe=%s, VD=%d)",
            nb, maxi,
            p.code_discipline, p.code_entite,
            p.categ, p.sexe, p.denivele
        )
    end

    -- OK
    return true, string.format(
        "OK : %d portes dans la plage [%d - %s] pour %s %s (Categ=%s, Sexe=%s, VD=%d)",
        nb, mini, maxi or "∞",
        p.code_discipline, p.code_entite,
        p.categ, p.sexe, p.denivele
    )
end

------------------------------------------------------------
-- 4. Point d'entrée appelé par skiFFS
------------------------------------------------------------
function main(params)
    -- params est un tableau Lua avec les clés en minuscules
    local ok, msg = check_gates(params)

    print(msg)
    return ok, msg
end

------------------------------------------------------------
-- Fin du fichier
------------------------------------------------------------
