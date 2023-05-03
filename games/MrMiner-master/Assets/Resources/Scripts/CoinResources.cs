using System;
using System.Numerics;
using TMPro;
using UnityEngine;
using utiles;
using Quaternion = UnityEngine.Quaternion;
using Random = UnityEngine.Random;
using Vector2 = UnityEngine.Vector2;
using Vector3 = UnityEngine.Vector3;

public class CoinResources : MonoBehaviour
{
    public AnimationCurve moveCurveX, moveCurveY, rotateCurveZ;
    [Range(0.001f, 1f)] public float speed = .5f;
    public float finalPosY = 1.2f;
    public AudioClip[] coinCollect;
    public GameObject glow;
    public Animator animator;

    private DataStorage _dataStorage;
    private AudioSource _audioSource;
    private float _timeStart;
    private Vector2 _startPoint;
    private bool _left;
    private float _totalAngle;
    private float _finalPosX;
    private BigInteger _value;
    private Camera _camera;
    private AudioClip _badge;
    private Animator _headerCoinValueAnimator;
    private ColorFade _headerCoinValueColorFade;
    private static readonly int Bounce = Animator.StringToHash("Bounce");
    private static readonly int Start1 = Animator.StringToHash("Start");
    private bool _clicked;

    private void Start()
    {
        _camera = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>();
        _audioSource = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<AudioSource>();
        _headerCoinValueAnimator = GameObject.Find("Header_coin_value").GetComponent<Animator>();
        _headerCoinValueColorFade = GameObject.Find("Header_coin_value").GetComponent<ColorFade>();
        _dataStorage = GameObject.FindGameObjectWithTag("DataStorage").GetComponent<DataStorage>();

        _left = Random.Range(0f, 1f) < .5f;
        var spawnZone = GameObject.Find(_left ? "LogSpawnZone_001" : "LogSpawnZone_002");
        _startPoint = utilies.RandomPointInCollider(spawnZone.GetComponent<PolygonCollider2D>(), _camera);
        transform.GetChild(0).GetComponent<SpriteRenderer>().flipX = Random.Range(0f, 1f) < .5f;
        _totalAngle = 360f * Random.Range(2,4) + Random.Range(-16f, 16f);

        _finalPosX = Random.Range(0, utilies.GetCameraBounds(_camera).x * 0.8f);
        _finalPosX = _left ? -_finalPosX : _finalPosX;
        finalPosY += Random.Range(-0.3f, 0.3f);

        var scale = Random.Range(0.7f, 1.0f);
        transform.localScale *= scale;
        _value = new BigInteger((double) _dataStorage.user.ClickPowerLog * 6f * Math.Pow(scale, 2f));

        _timeStart = Time.time;
    }

    private void Update()
    {
        var t = Time.time - _timeStart;
        if (t * speed > 1)
            return;

        var pos = new Vector3(
            _startPoint.x + (_finalPosX - _startPoint.x) * moveCurveX.Evaluate(t * speed),
            _startPoint.y + (finalPosY - _startPoint.y) * moveCurveY.Evaluate(t * speed),
            0f);
        var rotation = transform.rotation;
        var angle = Quaternion.Euler(rotation.x, rotation.y,
            _totalAngle * rotateCurveZ.Evaluate(t * speed));
        transform.SetPositionAndRotation(pos, angle);
    }

    private void OnMouseEnter()
    {
        if (_clicked)
            return;
        transform.localScale *= 1.3f;
        glow.SetActive(true);
    }

    private void OnMouseExit()
    {
        if (_clicked)
            return;
        transform.localScale /= 1.3f;
        glow.SetActive(false);
    }

    private void OnMouseUp()
    {
        if (_clicked)
            return;
        _audioSource.PlayOneShot(coinCollect[Random.Range(0, coinCollect.Length)]);
        Effect.ClickEffect(_camera.ScreenToWorldPoint(Input.mousePosition), Color.yellow);
        _headerCoinValueAnimator.SetTrigger(Bounce);
        _headerCoinValueColorFade
            .FadeToColor(Color.white, utilies.HexToColor("#FFFD73"), typeof(TextMeshProUGUI));
        _dataStorage.user.EarnClickCoin(_value, false);
        Effect.SpawnFloatingText(Input.mousePosition, _value, 1.6f);
        animator.SetTrigger(Start1);
        _clicked = true;
    }

    public void End()
    {
        Destroy(gameObject);
    }
}