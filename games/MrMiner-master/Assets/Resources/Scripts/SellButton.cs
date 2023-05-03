using UnityEngine;
using utiles;

public class SellButton : MonoBehaviour
{
    public AudioClip[] sold, damage;
    public AudioClip beep, overheat, rebuilt;
    public AnimationCurve onPressCurve, timeToNextSell;
    public Transform coin;
    public float timeToStart = 1f;
    public int maxClicks = 100;
    public SpriteRenderer glowSpriteRenderer, coinSpriteRenderer;
    public float cooldownTime = 5, rebuiltTime = 10;
    public Animator overheatAnimator;
    public bool overheated;
    public float coinDropChance = 0.5f;
    public GameObject dropCoin;

    private static AudioClip _mouseDownAudioClip;
    private static AudioClip _mouseUpAudioClip;
    private AudioSource _audioSource;
    private bool _onDownAnimation, _onUpAnimation;
    private float _timeStart;
    private float _shopBaseInitialLocalPosY;
    private float _lastSell;
    private Camera _camera;
    private DataStorage _dataStorage;
    private int _clicks;
    private SpriteRenderer _spriteRenderer;
    private Color _lastColor, _lastColorCoin;
    private bool _cool = true;
    private float _overheatedTime;
    private float _clickBackup;
    private static readonly int Start1 = Animator.StringToHash("Start");
    private static readonly int Inverse = Animator.StringToHash("Inverse");

    private void Start()
    {
        _dataStorage = GameObject.FindGameObjectWithTag("DataStorage").GetComponent<DataStorage>();
        _mouseDownAudioClip = Resources.Load("Raws/click_down_003") as AudioClip;
        _mouseUpAudioClip = Resources.Load("Raws/click_up_002") as AudioClip;
        _audioSource = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>()
            .GetComponent<AudioSource>();
        _shopBaseInitialLocalPosY = transform.localPosition.y;
        _camera = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>();
        _spriteRenderer = GetComponent<SpriteRenderer>();
    }

    private void Update()
    {
        if (!_onDownAnimation && !_onUpAnimation)
            return;

        var t = Time.time - _timeStart;
        float localY = default;
        if (_onDownAnimation)
            localY = -0.18f * onPressCurve.Evaluate(t * 1 / 0.06f);
        else if (_onUpAnimation)
            localY = -0.18f + 0.18f * onPressCurve.Evaluate(t * 1 / 0.06f);

        transform.localPosition = new Vector2(0, _shopBaseInitialLocalPosY + localY);
        coin.localPosition = new Vector2(0, _shopBaseInitialLocalPosY + localY);

        if (_onDownAnimation && !overheated)
        {
            if (t > timeToStart && Time.time - _lastSell > timeToNextSell.Evaluate(t))
            {
                _clickBackup = 0;
                ++_clicks;
                if (_clicks >= maxClicks)
                {
                    OnMouseUp();
                    overheated = true;
                    _overheatedTime = Time.time;
                    _audioSource.PlayOneShot(overheat);
                    overheatAnimator.enabled = true;
                    overheatAnimator.SetTrigger(Start1);
                    _onDownAnimation = false;
                    return;
                }

                _cool = false;
                _lastSell = Time.time;
                Effect.ClickEffect(_camera.ScreenToWorldPoint(Input.mousePosition), utilies.HexToColor("#A5FAFF"));
                Effect.SpawnFloatingText(Input.mousePosition, _dataStorage.user.ClickPowerCoin, 1.6f, "#FFD87C");
                _dataStorage.user.EarnClickCoin();
                if (Random.Range(0f, 1f) < coinDropChance)
                {
                    var log = Instantiate(dropCoin);
                    log.GetComponent<CoinResources>().speed = 1-timeToNextSell.Evaluate(t);
                }

                if ((_clicks % (maxClicks / 4) == 0))
                    _audioSource.PlayOneShot(damage[Random.Range(0, damage.Length)]);
                else
                    _audioSource.PlayOneShot(sold[Random.Range(0, sold.Length)]);

                _lastColor = Color.Lerp(utilies.HexToColor("#FFDA00"), utilies.HexToColor("#EC0005"),
                    (float) _clicks / maxClicks);
                _spriteRenderer.color = _lastColor;

                _lastColorCoin = Color.Lerp(Color.white, utilies.HexToColor("#EC0005"),
                    (float) _clicks / maxClicks);
                coinSpriteRenderer.color = _lastColorCoin;

                var glowColor = _lastColor;
                glowColor.a = 0.1f + (float) _clicks / maxClicks;
                glowSpriteRenderer.color = glowColor;
            }
        }

        if (_onUpAnimation && !_cool)
        {
            if (_clickBackup == 0)
                _clickBackup = _clicks;
            var heat = cooldownTime * _clickBackup / maxClicks;
            if (t / heat >= 1)
            {
                _clicks = 0;
                _cool = true;
                _audioSource.PlayOneShot(beep);
            }

            _clicks = (int) (_clickBackup * (1f - t / heat));

            var color = Color.Lerp(_lastColor, utilies.HexToColor("#FFDA00"), t / heat);
            _spriteRenderer.color = color;
            coinSpriteRenderer.color = Color.Lerp(_lastColorCoin, Color.white, t / heat);
            color.a = 1.2f - t / heat;
            glowSpriteRenderer.color = color;
        }

        if (overheated && Time.time - _overheatedTime > rebuiltTime)
        {
            overheated = false;
            overheatAnimator.enabled = true;
            overheatAnimator.SetTrigger(Inverse);
            _audioSource.PlayOneShot(rebuilt);
        }
    }

    private void OnMouseDown()
    {
        if (overheated)
            return;
        _audioSource.PlayOneShot(_mouseDownAudioClip);
        _timeStart = Time.time;
        _onDownAnimation = true;
        _onUpAnimation = false;
    }

    private void OnMouseUp()
    {
        if (overheated)
            return;
        _audioSource.PlayOneShot(_mouseUpAudioClip);
        _timeStart = Time.time;
        _onDownAnimation = false;
        _onUpAnimation = true;
    }
}