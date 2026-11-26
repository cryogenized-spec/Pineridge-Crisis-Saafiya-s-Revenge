"""Character proportions, wardrobe palettes and art-space weapon pose profiles."""
from dataclasses import dataclass

BODY_BASES = {
    "slim": (.96, .92, .91),
    "balanced": (1.0, 1.0, 1.0),
    "broad": (1.04, 1.15, 1.105),
}


@dataclass(frozen=True)
class Look:
    key: str
    label: str
    sex: str
    base: str
    skin: str
    hair: str
    top: str
    pants: str
    footwear: str
    style: str
    accent: str
    detail: str = ""


HERO = Look("saafiya", "Saafiya", "female", "balanced", "a6704e",
            "saafiya_curls", "4a354b", "3b2a3d", "27202c", "leather", "b98a61", "signature")
LOOKS = [
    Look("male_01", "Charcoal commuter", "male", "slim", "76513c", "fade",
         "464d58", "494854", "282931", "bomber", "a3a6a4", "glasses"),
    Look("male_02", "Saffron runner", "male", "balanced", "a46e4c", "twists",
         "ab814b", "464b65", "393447", "windbreaker", "dbc29e"),
    Look("male_03", "Teal work shirt", "male", "broad", "855138", "shaved",
         "427173", "6f6556", "42413b", "workwear", "c6b386"),
    Look("male_04", "Oxblood knit", "male", "broad", "bb8764", "waves",
         "793c48", "4a424a", "332b30", "knit", "bf8267", "beard"),
    Look("male_05", "Indigo denim", "male", "slim", "92603f", "coils",
         "515e7d", "52474a", "38383c", "denim", "a7a5a7"),
    Look("female_01", "Scarlet raincoat", "female", "balanced", "89583e", "bun",
         "9f5455", "423a51", "392d38", "raincoat", "d0a185"),
    Look("female_02", "Sage utility jacket", "female", "broad", "714630", "coils",
         "6d7864", "485258", "403d34", "workwear", "bdad88"),
    Look("female_03", "Russet wrap", "female", "slim", "be8662", "braids",
         "a76b57", "5a5354", "43343b", "wrap", "dfb194", "hoops"),
    Look("female_04", "Cream blouse", "female", "broad", "906952", "puff",
         "c6b9a2", "495a79", "413640", "blouse", "8d665f"),
    Look("female_05", "Indigo jacket", "female", "balanced", "a66948", "ponytail",
         "59597f", "68585c", "3e343c", "bomber", "ab909b", "glasses"),
]

POSE_NAMES = ("ready", "recoil", "service", "return")


@dataclass(frozen=True)
class Gear:
    ident: str
    name: str
    action: str
    grip: tuple
    support: tuple
    width: float
    muzzle: float
    port: float
    case: str


# Socket and prop coordinates are visual registration values in the art scene.
GEAR = [
    Gear("beretta_84fs", "Beretta 84FS", "slide", (.09,-.417,1.27), (.026,-.422,1.24), 22.0, .83, .10, "short"),
    Gear("cz75_p07", "CZ 75 P-07", "slide", (.038,-.443,1.29), (-.037,-.424,1.246), 22.0, .94, .17, "short"),
    Gear("norinco_akm", "Norinco AKM", "bolt", (.105,-.325,1.285), (.066,-.62,1.265), 27.0, 1.28, .28, "long"),
    Gear("pump_shotgun", "Mossberg-style pump shotgun", "pump", (.076,-.322,1.32), (.020,-.568,1.28), 27.0, 1.32, .23, "shell"),
    Gear("canik_tp9", "Canik TP9", "slide", (.029,-.414,1.265), (-.052,-.469,1.221), 22.0, .95, .22, "short"),
    Gear("sw_revolver_engraved", "S&W Model 640", "revolver", (.127,-.412,1.32), (-.145,-.275,1.17), 21.0, .72, .16, ""),
    Gear("fairbairn_sykes", "Fairbairn–Sykes", "blade", (.189,-.235,1.18), (-.168,-.206,1.19), 18.0, .79, 0., ""),
    Gear("spetsnaz_sf", "Spetsnaz SF", "blade", (.199,-.17,1.256), (-.176,-.24,1.21), 19.0, .87, 0., ""),
    Gear("akm_bayonet", "AKM bayonet", "blade", (.178,-.245,1.20), (-.161,-.178,1.14), 20.0, .98, 0., ""),
]


def pose_hands(gear, pose):
    main, support = gear.grip, gear.support
    if pose == "recoil":
        # Distinct silhouettes on visual discharge or a held-prop gesture.
        reach = -.055 if gear.action == "blade" else (.040 if gear.action == "bolt" else .058)
        main = (main[0]+.009, main[1]+reach, main[2]+.036)
        support = (support[0]+.014, support[1]+reach*.72, support[2]+.022)
    elif pose == "service":
        main = (main[0]+.063, main[1]+.136, main[2]-.092)
        support = (-.125, main[1]+.055, main[2]-.09)
    elif pose == "return":
        main = (main[0]+.029, main[1]+.074, main[2]-.04)
        support = (main[0]-.09, main[1]+.031, main[2]-.073)
    return (main, support)
