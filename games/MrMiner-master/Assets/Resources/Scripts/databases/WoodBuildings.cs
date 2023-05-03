using System.Numerics;

public abstract class WoodBuildings
{
    public static readonly Building[] Buildings =
    {
        new("Mighty Fist", BigInteger.Parse("15"), "#FFFF6D", .1f, "Sprites/BuildingsWood/1_Fist",
            BigInteger.Parse("100"),""),
        new("Metal Axe", BigInteger.Parse("100"), "#FFC578", 1f, "Sprites/BuildingsWood/2_Axe",
            BigInteger.Parse("1000"),""),
        new("Chainsaw", BigInteger.Parse("1100"), "#86FF96", 8f, "Sprites/BuildingsWood/3_Chainsaw",
            BigInteger.Parse("11000"),""),
        new("Woodsman", BigInteger.Parse("12000"), "#FFA7B1", 47f, "Sprites/BuildingsWood/4_Woodsman",
            BigInteger.Parse("120000"),""),
        new("Golden Tree", BigInteger.Parse("130000"), "#83B6FF", 260f, "Sprites/BuildingsWood/5_GoldenTree",
            BigInteger.Parse("1300000"),""),
        new("Forest", BigInteger.Parse("1400000"), "#CC92FF", 1400f, "Sprites/BuildingsWood/6_Forest",
            BigInteger.Parse("14000000"),""),
        new("Mountain", BigInteger.Parse("20000000"), "#FFEC72", 7800f, "Sprites/BuildingsWood/7_Mountain",
            BigInteger.Parse("200000000"),""),
        new("Wooden House", BigInteger.Parse("330000000"), "#5EE694", 44000f, "Sprites/BuildingsWood/8_WoodenHouse",
            BigInteger.Parse("3300000000"),""),
        new("Sawmill", BigInteger.Parse("5100000000"), "#9CFFEF", 260000f, "Sprites/BuildingsWood/9_Sawmill",
            BigInteger.Parse("51000000000"),""),
        new("Factory", BigInteger.Parse("75000000000"), "#CFB99C", 1600000f, "Sprites/BuildingsWood/10_Factory",
            BigInteger.Parse("75000000000"),""),
        new("Corporation", BigInteger.Parse("1000000000000"), "#A1AEBD", 10000000f,
            "Sprites/BuildingsWood/11_Corporation",
            BigInteger.Parse("1000000000000"),""),
        new("Spaceship", BigInteger.Parse("14000000000000"), "#F5F5F5", 65000000f, "Sprites/BuildingsWood/12_Spaceship",
            BigInteger.Parse("14000000000000"),""),
        new("Portal", BigInteger.Parse("170000000000000"), "#D96868", 430000000f, "Sprites/BuildingsWood/13_Portal",
            BigInteger.Parse("170000000000000"),""),
        new("Creator", BigInteger.Parse("21000000000000000"), "#545454", 2900000000f,
            "Sprites/BuildingsWood/14_Creator",
            BigInteger.Parse("2100000000000000"),"")
    };

    public static readonly int[] CostMultiply = {1, 5, 10, 100, 100, 100, 1000, 1000, 1000, 1000, 10000};
    public static readonly int[] RequiredProgress = {1, 5, 25, 50, 100, 150, 200, 250, 300, 350, 400};
    public static readonly int[] CostMultiplyFist = {1, 5, 20, 10, 100, 10, 10, 10, 1000, 1000, 1000, 1000};
    public static readonly int[] RequiredProgressFist = {1, 1, 5, 25, 50, 100, 150, 200, 250, 300, 350, 400};
}