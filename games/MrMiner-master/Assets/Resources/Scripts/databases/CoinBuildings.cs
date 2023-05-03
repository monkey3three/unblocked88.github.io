using System.Numerics;

public static class CoinBuildings
{
    public static readonly Store[] Stores =
    {
        new("Sign", BigInteger.Parse("15"), "#D0DEB5", .1f, "Sprites/BuildingsStore/1_Sign",
            BigInteger.Parse("100"), ""),
        new("Clover", BigInteger.Parse("100"), "#D96868", 1f, "Sprites/BuildingsStore/2_Clover",
            BigInteger.Parse("1000"), ""),
        new("Foliage", BigInteger.Parse("1100"), "#86FF96", 8f, "Sprites/BuildingsStore/3_Plant",
            BigInteger.Parse("11000"), ""),
        new("Land", BigInteger.Parse("12000"), "#CC92FF", 47f, "Sprites/BuildingsStore/4_Land",
            BigInteger.Parse("120000"), ""),
        new("Worker", BigInteger.Parse("130000"), "#F5F5F5", 260f, "Sprites/BuildingsStore/5_Worker",
            BigInteger.Parse("1300000"), ""),
        new("Merchant", BigInteger.Parse("1400000"), "#CC92FF", 1400f, "Sprites/BuildingsStore/6_Merchant",
            BigInteger.Parse("14000000"), ""),
        new("Businessman", BigInteger.Parse("20000000"), "#9CFFEF", 7800f, "Sprites/BuildingsStore/7_Businessman",
            BigInteger.Parse("200000000"), ""),
        new("Shop", BigInteger.Parse("330000000"), "#CFB99C", 44000f, "Sprites/BuildingsStore/8_Shop",
            BigInteger.Parse("3300000000"), ""),
        new("Mall", BigInteger.Parse("5100000000"), "#D6AEDE", 260000f, "Sprites/BuildingsStore/9_Mall",
            BigInteger.Parse("51000000000"), ""),
        new("Bank", BigInteger.Parse("75000000000"), "#96DAE3", 1600000f, "Sprites/BuildingsStore/10_Bank",
            BigInteger.Parse("75000000000"), ""),
        new("Boat", BigInteger.Parse("1000000000000"), "#F5F5F5", 10000000f,
            "Sprites/BuildingsStore/11_Boat",
            BigInteger.Parse("1000000000000"), ""),
        new("Handshake", BigInteger.Parse("14000000000000"), "#A2E371", 65000000f,
            "Sprites/BuildingsStore/12_Handshake",
            BigInteger.Parse("14000000000000"), ""),
        new("Company", BigInteger.Parse("170000000000000"), "#D0D0D1", 430000000f, "Sprites/BuildingsStore/13_Company",
            BigInteger.Parse("170000000000000"), ""),
        new("MrRich", BigInteger.Parse("21000000000000000"), "#545454", 2900000000f,
            "Sprites/BuildingsStore/14_MrRich",
            BigInteger.Parse("2100000000000000"), "")
    };

    public static readonly int[] CostMultiply = {1, 5, 10, 100, 100, 100, 1000, 1000, 1000, 1000, 10000};
    public static readonly int[] RequiredProgress = {1, 5, 25, 50, 100, 150, 200, 250, 300, 350, 400};
}