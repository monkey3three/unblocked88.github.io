using System;
using System.Numerics;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using Vector2 = UnityEngine.Vector2;

public class ShopItem : MonoBehaviour, IPointerDownHandler, IPointerClickHandler,
    IPointerUpHandler
{
    public enum ShopItemType
    {
        LOG,
        COIN
    }

    private static AudioClip _mouseDownAudioClip;
    private static AudioClip _mouseUpAudioClip;
    private static AudioClip _notEnoughMoney;
    private static AudioClip _bought;
    private static AudioClip _boughtUpdate;
    private static AudioClip _charge;
    private static AudioClip _updateOn;
    private static AudioClip _updateOff;

    public float downTimeForUpdate = 1;
    public GameObject shopItemHold;
    public AnimationCurve onPressCurve;
    public float onPressAnimationDuration = 0.5f;
    [NonSerialized] public int Index;
    [NonSerialized] public ShopItemType shopItemType;
    public ColorFade infoModeColorFade;

    private bool _onDownAnimation;
    private bool _onUpAnimation;
    private float _downTime;
    private float _timeStart;
    private float _onPressAnimationScale;
    private float _shopBaseInitialLocalPosY;
    private bool _updateMode;
    private bool _holdStarted;
    private bool _forcedUp;
    private Image _shopItemHoldImage;
    private RectTransform _shopItemHoldRectTransform;
    private Transform _shopBase;
    private AudioSource _audioSource;
    private TextMeshProUGUI _shopItemPriceUpgradeText;
    private TextMeshProUGUI _shopItemVersionText;
    private TextMeshProUGUI _shopItemValue;
    private TextMeshProUGUI _shopItemDescription;
    private TextMeshProUGUI _shopItemPs;
    private Image _shopInfoMode;
    private DataStorage _dataStorage;
    private ColorFade _upgradePriceTextColorFade;
    private ColorFade _shopAvailabilityColorFade;
    private ColorFade _priceTextColorFade;
    private Animator _animator;
    private static InfoMode _infoMode;
    private Store _userStore;
    private Building _userBuilding;


    public void Start()
    {
        _dataStorage = GameObject.FindGameObjectWithTag("DataStorage").GetComponent<DataStorage>();
        _shopBase = transform.GetChild(1);
        _mouseDownAudioClip = Resources.Load("Raws/click_down_003") as AudioClip;
        _mouseUpAudioClip = Resources.Load("Raws/click_up_002") as AudioClip;
        _bought = Resources.Load("Raws/buy") as AudioClip;
        _boughtUpdate = Resources.Load("Raws/other_jump7") as AudioClip;
        _notEnoughMoney = Resources.Load("Raws/fx_no_buy") as AudioClip;
        _charge = Resources.Load("Raws/charge_01") as AudioClip;
        _updateOn = Resources.Load("Raws/upgrade_01") as AudioClip;
        _updateOff = Resources.Load("Raws/upgrade_02") as AudioClip;
        _onPressAnimationScale = 1 / onPressAnimationDuration;
        _shopBaseInitialLocalPosY = _shopBase.localPosition.y;
        _shopItemHoldImage = shopItemHold.GetComponent<Image>();
        _shopItemHoldRectTransform = shopItemHold.GetComponent<RectTransform>();
        _audioSource = GetComponent<AudioSource>();
        _shopItemPriceUpgradeText = _shopBase.Find("ShopItem_price_upgrade").GetComponent<TextMeshProUGUI>();
        _shopItemVersionText = _shopBase.Find("ShopItem_version").GetComponent<TextMeshProUGUI>();
        _shopItemValue = _shopBase.Find("ShopItem_value").GetComponent<TextMeshProUGUI>();
        _upgradePriceTextColorFade = _shopBase.transform.Find("ShopItem_price_upgrade").GetComponent<ColorFade>();
        _shopAvailabilityColorFade = _shopBase.Find("ShopItem_availability").gameObject.GetComponent<ColorFade>();
        _priceTextColorFade = _shopBase.transform.Find("ShopItem_price").GetComponent<TextMeshProUGUI>()
            .GetComponent<ColorFade>();
        _animator = GetComponent<Animator>();
        if (_infoMode == null)
            _infoMode = GameObject.FindWithTag("InfoMode").GetComponent<InfoMode>();
        _shopItemDescription = _shopBase.Find("ShopItem_description").GetComponent<TextMeshProUGUI>();

        _shopItemPs = _shopBase.Find("ShopItem_ps").GetComponent<TextMeshProUGUI>();
        _shopBase.Find("ShopItem_ps").gameObject.SetActive(false);

        _shopInfoMode = _shopBase.Find("ShopItem_info_mode").GetComponent<Image>();
        _userStore = _dataStorage.user.stores[Index];
        _userBuilding = _dataStorage.user.buildings[Index];
    }

    private void Update()
    {
        var t = Time.time - _timeStart;

        if (!_onDownAnimation && !_onUpAnimation)
        {
            var color = _shopItemHoldImage.color;
            if (color.a > 0.01f)
            {
                color.a = 1 - t * 3;
                _shopItemHoldImage.color = color;
            }

            return;
        }


        if (t * _onPressAnimationScale <= 1f)
        {
            float localY = default;
            if (_onDownAnimation)
                localY = -15f * onPressCurve.Evaluate(t * _onPressAnimationScale);
            else if (_onUpAnimation)
                localY = -15f + 15f * onPressCurve.Evaluate(t * _onPressAnimationScale);

            _shopBase.localPosition = new Vector2(0, _shopBaseInitialLocalPosY + localY);
        }

        if (t * _onPressAnimationScale > 1f)
            _onUpAnimation = false;

        if (!_updateMode)
            return;

        var newT = (t * _onPressAnimationScale - 1f) / (_onPressAnimationScale * downTimeForUpdate);

        if (newT > 0.15f)
        {
            if (!_onDownAnimation)
                return;

            if (!_holdStarted)
            {
                _shopItemHoldRectTransform.position = Input.mousePosition;
                _audioSource.PlayOneShot(_charge);
            }

            _holdStarted = true;
            _shopItemHoldRectTransform.localScale =
                Vector2.one * (0.5f + 18f * newT);

            var color = _shopItemHoldImage.color;
            color.a = newT;
            _shopItemHoldImage.color = color;
            if (newT > 0.86f)
            {
                _forcedUp = true;
                OnPointerUp(null);
                BuyUpgrade();
            }
        }
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if(_infoMode.Mode)
            return;
        if (_forcedUp)
        {
            _forcedUp = false;
            return;
        }

        if (_downTime > downTimeForUpdate)
            BuyUpgrade();
        else if (_downTime < downTimeForUpdate * 0.4f)
            Buy();
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        _audioSource.PlayOneShot(_mouseDownAudioClip);
        _onDownAnimation = true;
        _onUpAnimation = false;
        _timeStart = Time.time;

        _shopBase.Find("ShopItem_highlight").gameObject.SetActive(true);
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        _holdStarted = false;
        _audioSource.PlayOneShot(_mouseUpAudioClip);
        _onDownAnimation = false;
        _onUpAnimation = true;
        _downTime = Time.time - _timeStart;
        _timeStart = Time.time;

        _shopBase.Find("ShopItem_highlight").gameObject.SetActive(false);
    }

    public void TurnUpgradeModeIfNecessary()
    {
        if (shopItemType == ShopItemType.LOG)
        {
            _shopItemPriceUpgradeText.text =
                utilies.NumToStr(_userBuilding.CurrentUpgradeCost);
            _shopItemVersionText.text = "lv." + _userBuilding.Version;

            if (_updateMode == _userBuilding.CheckForUpgrade())
                return;
        }
        else
        {
            _shopItemPriceUpgradeText.text =
                utilies.NumToStr(_userStore.CurrentUpgradeCost);
            _shopItemVersionText.text = "lv." + _userStore.Version;

            if (_updateMode == _userStore.CheckForUpgrade())
                return;
        }

        _updateMode = !_updateMode;
        _animator.enabled = true;
        _animator.SetTrigger(_updateMode ? "Open" : "Close");
        if (Time.time > 2)
            _audioSource.PlayOneShot(_updateMode ? _updateOn : _updateOff);
    }

    public void TurnAvailability(bool force = false)
    {
        bool mode;
        if (shopItemType == ShopItemType.LOG)
        {
            mode = _dataStorage.user.EnoughForBuilding(Index);
            if (!force && _userBuilding.buildingAvailable == mode)
                return;
            _userBuilding.buildingAvailable = mode;
        }
        else
        {
            mode = _dataStorage.user.EnoughForStore(Index);
            if (!force && _userStore.buildingAvailable == mode)
                return;
            _userStore.buildingAvailable = mode;
        }

        var colorFinal = mode ? Color.clear : new Color(0f, 0f, 0f, 0.6f);
        var colorInitial = !mode ? Color.clear : new Color(0f, 0f, 0f, 0.6f);
        _shopAvailabilityColorFade.FadeToColor(colorInitial, colorFinal, typeof(Image));

        colorFinal = mode ? Color.green : Color.gray;
        colorInitial = !mode ? Color.green : Color.gray;
        _priceTextColorFade.FadeToColor(colorInitial, colorFinal, typeof(TextMeshProUGUI));
    }

    public void TurnUpgradeAvailability(bool force = false)
    {
        bool upgradeMode;
        if (shopItemType == ShopItemType.LOG)
        {
            if (!_userBuilding.CheckForUpgrade())
                return;
            upgradeMode = _dataStorage.user.EnoughForUpgradeBuilding(Index);
            if (!force && _userBuilding.upgradeAvailable == upgradeMode)
                return;
            _userBuilding.upgradeAvailable = upgradeMode;
        }
        else
        {
            if (!_userStore.CheckForUpgrade())
                return;
            upgradeMode = _dataStorage.user.EnoughForUpgradeStore(Index);
            if (!force && _userStore.upgradeAvailable == upgradeMode)
                return;
            _userStore.upgradeAvailable = upgradeMode;
        }

        var colorFinal = upgradeMode ? utilies.HexToColor("#F2FF72") : Color.gray;
        var colorInitial = !upgradeMode ? utilies.HexToColor("#F2FF72") : Color.gray;

        _upgradePriceTextColorFade.FadeToColor(colorInitial, colorFinal, typeof(TextMeshProUGUI));
    }


    private void Buy()
    {
        var buyCond = shopItemType == ShopItemType.LOG
            ? _dataStorage.user.Buy(_userBuilding)
            : _dataStorage.user.Buy(_userStore);
        if (buyCond)
        {
            _audioSource.PlayOneShot(_bought);
            TurnUpgradeModeIfNecessary();
        }
        else
            _audioSource.PlayOneShot(_notEnoughMoney);
    }

    private void BuyUpgrade()
    {
        var buyCond = shopItemType == ShopItemType.LOG
            ? _dataStorage.user.BuyUpgrade(_userBuilding)
            : _dataStorage.user.BuyUpgrade(_userStore);
        if (buyCond)
        {
            TurnUpgradeModeIfNecessary();
            _audioSource.PlayOneShot(_boughtUpdate);
        }
        else
            _audioSource.PlayOneShot(_notEnoughMoney);
    }

    private void ShopItemValueTextSwitch()
    {
        var perc = shopItemType == ShopItemType.LOG
            ? _userBuilding.Lps * 100 / _dataStorage.user.Lps
            : _userStore.Cps * 100 / _dataStorage.user.Cps;

        var count = shopItemType == ShopItemType.LOG
            ? _userBuilding.Count
            : _userStore.Count;

        var description = shopItemType == ShopItemType.LOG
            ? _userBuilding.Description
            : _userStore.Description;

        var ps = shopItemType == ShopItemType.LOG
            ? utilies.DoubleToStr(_userBuilding.Lps) + "lps"
            : utilies.DoubleToStr(_userStore.Cps) + "cps";

        _shopItemValue.text = _infoMode.Mode ? perc.ToString("n2")+"%" : count.ToString();
        _shopItemDescription.text = description;
        _shopItemPs.text = ps;
    }

    private void InfoModeFadeToColor()
    {
        var perc = shopItemType == ShopItemType.LOG
            ? _userBuilding.Lps / _dataStorage.user.Lps
            : _userStore.Cps / _dataStorage.user.Cps;
        var color = shopItemType == ShopItemType.LOG
            ? _userBuilding.Color
            : _userStore.Color;
        infoModeColorFade.FadeToColor(utilies.HexToColor("#636363"), 
            Color.Lerp(utilies.HexToColor("#636363"),utilies.HexToColor(color),(float) (perc)),
            typeof(Image));
    }
}