using System;
using System.Linq;
using System.Numerics;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using Vector2 = UnityEngine.Vector2;

[Serializable]
public class Store
{
    public int Version { get; private set; }
    public int Count { get; private set; }
    public string Color { get; }
    private BigInteger UpgradeBaseCost { get; }
    public bool buildingAvailable, upgradeAvailable;

    private string Name { get; }
    public BigInteger BaseCost { get; }
    private double BaseCps { get; }
    private string Logo { get; }
    public bool unlocked;
    public string Description { get;}

    public Store(string name, BigInteger baseCost, string colorHex, double baseCps, string logo,
        BigInteger upgradeBaseCost, string description)
    {
        Name = name;
        BaseCost = new BigInteger((double) baseCost * 2.75d);
        BaseCps = baseCps * 2;
        Logo = logo;
        Version = 0;
        Count = 0;
        Color = colorHex;
        UpgradeBaseCost = upgradeBaseCost;
        Description = description;
    }

    public void Upgrade()
    {
        ++Version;
    }

    public bool CheckForUpgrade()
    {
        var requirements = CoinBuildings.RequiredProgress;
        var upgradesAvailable = requirements.Count(requirement => Count >= requirement);
        return upgradesAvailable > Version;
    }

    public BigInteger CurrentUpgradeCost
    {
        get
        {
            var cost = UpgradeBaseCost;
            for (var i = 0; i < Version + 1; i++)
                cost = BigInteger.Multiply(cost, new BigInteger(CoinBuildings.CostMultiply[i]));
            return cost;
        }
    }

    public void Buy()
    {
        ++Count;
    }

    public BigInteger CurrentCost => new((double) BaseCost * Math.Pow(1.15f, Count));

    public double Cps => BaseCps * Count * Mathf.Pow(2, Version);

    public GameObject InstantiateGameObject(GameObject building, int index)
    {
        var logo = Resources.Load<Sprite>(Logo);
        var logoCoin = Resources.Load<Sprite>("Sprites/Coin_3");

        building.GetComponent<ShopItem>().Index = index;
        building.tag = "ShopItemCoin";
        building.GetComponent<ShopItem>().shopItemType = ShopItem.ShopItemType.COIN;

        var shopBase = building.transform.Find("ShopItem_base").gameObject;
        shopBase.GetComponent<Image>().color = utilies.HexToColor(Color);
        if (Color == "#545454")
        {
            shopBase.transform.Find("ShopItem_value").GetComponent<TextMeshProUGUI>().color =
                utilies.HexToColor("#AEA1AE");
            shopBase.transform.Find("ShopItem_name").GetComponent<TextMeshProUGUI>().color =
                utilies.HexToColor("#9F8D9F");
        }

        shopBase.transform.Find("ShopItem_name").GetComponent<TextMeshProUGUI>().text = Name;
        shopBase.transform.Find("ShopItem_price").GetComponent<TextMeshProUGUI>().text =
            utilies.NumToStr(CurrentCost);
        shopBase.transform.Find("ShopItem_value").GetComponent<TextMeshProUGUI>().text = Count.ToString();
        shopBase.transform.Find("ShopItem_logo").GetComponent<Image>().sprite = logo;
        shopBase.transform.Find("ShopItem_log").GetComponent<Image>().sprite = logoCoin;

        var xScaleFactor = logo.bounds.size.x / logo.bounds.size.y / 0.942445993f;
        var rect = shopBase.transform.Find("ShopItem_logo").GetComponent<RectTransform>().rect;
        rect.width *= xScaleFactor;
        shopBase.transform.Find("ShopItem_logo").GetComponent<RectTransform>().sizeDelta =
            new Vector2(rect.width, rect.height);
        shopBase.transform.Find("ShopItem_version").GetComponent<TextMeshProUGUI>().text = "lv." + Version;

        rect = shopBase.transform.Find("ShopItem_log").GetComponent<RectTransform>().rect;
        shopBase.transform.Find("ShopItem_log").GetComponent<RectTransform>().sizeDelta =
            new Vector2(rect.height, rect.height);
        return building;
    }
}