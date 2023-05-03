using UnityEngine;

public class PopulateScrollView : MonoBehaviour
{
    public GameObject space;

    public void Populate(User user)
    {
        var index = 0;
        foreach (var building in WoodBuildings.Buildings)
        {
            var buildingToAdd = building.InstantiateGameObject(Instantiate(
                    Resources.Load<GameObject>("Prefabs/ShopItem"),
                    GameObject.Find("Content").transform, false), index++
            );
            user.ShopItemBuilding.Add(buildingToAdd);
            user.ShopItemBuildingAnimators.Add(buildingToAdd.GetComponent<Animator>());
        }

        Instantiate(space, GameObject.Find("Content").transform, false);
        index = 0;
        foreach (var store in CoinBuildings.Stores)
        {
            var shopToAdd = store.InstantiateGameObject(Instantiate(
                    Resources.Load<GameObject>("Prefabs/ShopItem"),
                    GameObject.Find("ContentCoin").transform, false), index++
            );
            user.ShopItemStore.Add(shopToAdd);
            user.ShopItemStoreAnimators.Add(shopToAdd.GetComponent<Animator>());
        }

        Instantiate(space, GameObject.Find("ContentCoin").transform, false);
    }
}