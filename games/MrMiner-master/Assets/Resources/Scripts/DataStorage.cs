using System.Linq;
using TMPro;
using UnityEngine;

public class DataStorage : MonoBehaviour
{
    public User user;
    public bool resetProgresses;
    public bool hideFar;
    public PopulateScrollView populateScrollView;

    private void Start()
    {
        user = !resetProgresses ? User.Load() : new User();
        populateScrollView.Populate(user);
        InitializeUser();

        foreach (var shopItem in GameObject.FindGameObjectsWithTag("ShopItem"))
        {
            shopItem.GetComponent<ShopItem>().Start();
            shopItem.GetComponent<ShopItem>().TurnAvailability(true);
            shopItem.GetComponent<ShopItem>().TurnUpgradeModeIfNecessary();
            shopItem.GetComponent<ShopItem>().TurnUpgradeAvailability(true);
        }

        foreach (var shopItem in GameObject.FindGameObjectsWithTag("ShopItemCoin"))
        {
            shopItem.GetComponent<ShopItem>().Start();
            shopItem.GetComponent<ShopItem>().TurnAvailability(true);
            shopItem.GetComponent<ShopItem>().TurnUpgradeModeIfNecessary();
            shopItem.GetComponent<ShopItem>().TurnUpgradeAvailability(true);
        }

        user.UpdateUI();
        user.UpdateBuildUI();
        
    }

    private void InitializeUser()
    {
        foreach (var building in user.buildings.Where(building => !building.unlocked))
            building.unlocked = true;
        foreach (var store in user.stores.Where(store => !store.unlocked))
            store.unlocked = true;
        
        user.ShopItemValueText = new();
        user.ShopItemPriceText = new();
        user.ShopItemCoinValueText = new();
        user.ShopItemCoinPriceText = new();
        var count = 0;
        foreach (var shopItem in GameObject.FindGameObjectsWithTag("ShopItem"))
        {
            var shopBase = shopItem.transform.Find("ShopItem_base");
            user.ShopItemValueText.Add(shopBase.Find("ShopItem_value").GetComponent<TextMeshProUGUI>());
            user.ShopItemPriceText.Add(shopBase.Find("ShopItem_price").GetComponent<TextMeshProUGUI>());
            if (!user.buildings[count++].unlocked)
                shopItem.gameObject.SetActive(false);
        }

        count = 0;
        foreach (var shopItem in GameObject.FindGameObjectsWithTag("ShopItemCoin"))
        {
            var shopBase = shopItem.transform.Find("ShopItem_base");
            user.ShopItemCoinValueText.Add(shopBase.Find("ShopItem_value").GetComponent<TextMeshProUGUI>());
            user.ShopItemCoinPriceText.Add(shopBase.Find("ShopItem_price").GetComponent<TextMeshProUGUI>());
            if (!user.stores[count++].unlocked)
                shopItem.gameObject.SetActive(false);
        }
    }
}