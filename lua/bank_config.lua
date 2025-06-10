BANK_CONFIG = {}

-- Configuration des équipes
BANK_CONFIG.MinGovernment = 0 -- Nombre minimum de policiers requis pour commencer un braquage (0 pour désactiver)
BANK_CONFIG.MinBankers = 0    -- Nombre minimum de banquiers requis pour commencer un braquage (0 pour désactiver)
BANK_CONFIG.MinPlayers = 0    -- Nombre minimum de joueurs requis pour commencer un braquage (0 pour désactiver)

-- Configuration des récompenses
BANK_CONFIG.BaseReward = 50000   -- Montant initial dans chaque coffre-fort
BANK_CONFIG.MaxReward = 300000   -- Récompense maximale pour un braquage réussi
BANK_CONFIG.SaviorReward = 8000  -- Récompense pour avoir tué le braqueur
BANK_CONFIG.Interest = 5000      -- Montant d'augmentation à chaque intérêt

-- Configuration des temps
BANK_CONFIG.RobberyTime = 180  -- Durée nécessaire pour finir un braquage
BANK_CONFIG.CooldownTime = 540 -- Temps d'attente entre chaque braquage (échec ou réussite)
BANK_CONFIG.InterestTime = 120 -- Délai entre chaque augmentation de la récompense

-- Configuration du gameplay
BANK_CONFIG.MaxDistance = 500 -- Distance maximale autorisée du coffre pendant le braquage
BANK_CONFIG.LoopSiren = true -- Répéter le son de la sirène ?

-- Configuration des métiers (Utilise le nom affiché dans le menu F4)
BANK_CONFIG.Government = { -- Équipes considérées comme forces de l'ordre
    ['Civil Protection'] = true,
    ['Example Name'] = true,
}

BANK_CONFIG.Bankers = { -- Équipes considérées comme banquiers
    ['Citizen'] = true,
    ['Example Name'] = true,
}

BANK_CONFIG.Robbers = { -- Équipes autorisées à braquer
    ['Gangster'] = true, 
    ['Example Name'] = true,
}