using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;

public class LpsCps : MonoBehaviour
{
    [Range(1, 120)] public int fps = 60;

    private float _startTime;
    private float _passedSecond;
    [SerializeField] public DataStorage dataStorage;
    private readonly List<ShopItem> _shopItemsBuilding = new(), _shopItemsStore = new();
    public Animator newShopItemAnimator, canvasAnimator;
    public GameObject newShopItem;
    private SpriteRenderer _newShopItemBuilding;
    private TextMeshProUGUI _newShopItemName, _newShopItemValue;
    private static readonly int Start1 = Animator.StringToHash("Start");
    private static readonly int ScrollViewHide = Animator.StringToHash("ScrollViewHide");
    private GameObject[] _findGameObjectsWithTag;
    public AudioSource audioSource;
    public AudioClip woosh;

    private void Start()
    {
        foreach (var shopItem in dataStorage.user.ShopItemBuilding)
            _shopItemsBuilding.Add(shopItem.GetComponent<ShopItem>());
        foreach (var shopItem in dataStorage.user.ShopItemStore)
            _shopItemsStore.Add(shopItem.GetComponent<ShopItem>());
        _newShopItemBuilding = newShopItem.transform.Find("NewShopItem_building").GetComponent<SpriteRenderer>();
        _newShopItemName = newShopItem.transform.Find("NewShopItem_name").GetComponent<TextMeshProUGUI>();
        _newShopItemValue = newShopItem.transform.Find("NewShopItem_value").GetComponent<TextMeshProUGUI>();

        _startTime = Time.time;
    }

    private void Update()
    {
        if (Time.time - _startTime > 1f / fps)
        {
            _startTime = Time.time;
            dataStorage.user.EarnLps(fps);
            dataStorage.user.EarnCps(fps);

            _passedSecond += 1f / fps;
            if (_passedSecond >= 0.8f)
            {
                _passedSecond -= 0.8f;
                var count = 0;
                foreach (var shopItem in _shopItemsBuilding.Where(_ => dataStorage.user.buildings[count++].unlocked))
                {
                    shopItem.TurnAvailability();
                    shopItem.TurnUpgradeAvailability();
                }

                count = 0;
                foreach (var shopItem in _shopItemsStore.Where(_ => dataStorage.user.stores[count++].unlocked))
                {
                    shopItem.TurnAvailability();
                    shopItem.TurnUpgradeAvailability();
                }

                if (dataStorage.hideFar && !canvasAnimator.enabled)
                {
                    var build = dataStorage.user.CheckAndUnlockBuilding();
                    if (build != null)
                    {
                        _newShopItemBuilding.sprite = build.LogoSprite;
                        _newShopItemName.text = build.Name;
                        _newShopItemValue.text = utilies.DoubleToStr(build.BaseLps) + " lps";
                        newShopItem.SetActive(true);
                        newShopItemAnimator.SetTrigger(Start1);
                        canvasAnimator.enabled = true;
                        canvasAnimator.SetTrigger(ScrollViewHide);
                        dataStorage.user.ShopItemBuilding[dataStorage.user.buildings.IndexOf(build)].SetActive(true);
                        audioSource.PlayOneShot(woosh);
                    }
                }
            }
        }
    }
}