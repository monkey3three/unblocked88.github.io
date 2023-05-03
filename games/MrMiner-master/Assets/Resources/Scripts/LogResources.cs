using System;
using System.Numerics;
using System.Runtime.CompilerServices;
using TMPro;
using UnityEngine;
using utiles;
using Quaternion = UnityEngine.Quaternion;
using Random = UnityEngine.Random;
using Vector2 = UnityEngine.Vector2;
using Vector3 = UnityEngine.Vector3;

public class LogResources : MonoBehaviour
{
    public AnimationCurve moveCurveX, moveCurveY, rotateCurveZ;
    [Range(0.001f, 1f)] public float speed = .5f;
    public float finalPosY = 1.2f;
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
    private Animator _headerLogValueAnimator;
    private ColorFade _headerLogValueColorFade;
    private static readonly int Bounce = Animator.StringToHash("Bounce");

    private void Start()
    {
        _camera = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>();
        _audioSource = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<AudioSource>();
        _badge = Resources.Load("Raws/badge") as AudioClip;
        _headerLogValueAnimator = GameObject.Find("Header_log_value").GetComponent<Animator>();
        _headerLogValueColorFade = GameObject.Find("Header_log_value").GetComponent<ColorFade>();
        _dataStorage = GameObject.FindGameObjectWithTag("DataStorage").GetComponent<DataStorage>();

        _left = Random.Range(0f, 1f) < .5f;
        var spawnZone = GameObject.Find(_left ? "LogSpawnZone_001" : "LogSpawnZone_002");
        _startPoint = utilies.RandomPointInCollider(spawnZone.GetComponent<PolygonCollider2D>(), _camera);
        GetComponent<SpriteRenderer>().flipX = Random.Range(0f, 1f) < .5f;
        _totalAngle = Random.Range(360 * 2f, 360 * 3f);

        _finalPosX = Random.Range(0, utilies.GetCameraBounds(_camera).x * 0.8f);
        _finalPosX = _left ? -_finalPosX : _finalPosX;
        finalPosY += Random.Range(-0.3f, 0.3f);

        var scale = Random.Range(0.8f, 1.2f);
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
        transform.localScale *= 1.3f;
        transform.GetChild(0).gameObject.SetActive(true);
    }

    private void OnMouseExit()
    {
        transform.localScale /= 1.3f;
        transform.GetChild(0).gameObject.SetActive(false);
    }

    private void OnMouseUp()
    {
        _audioSource.PlayOneShot(_badge);
        Effect.ClickEffect(_camera.ScreenToWorldPoint(Input.mousePosition), utilies.HexToColor("#F8DB95"));
        _headerLogValueAnimator.SetTrigger(Bounce);
        _headerLogValueColorFade
            .FadeToColor(Color.white, utilies.HexToColor("#FFFD73"), typeof(TextMeshProUGUI));
        _dataStorage.user.EarnClickLog(_value);
        Effect.SpawnFloatingText(Input.mousePosition, _value, 1.6f);
        Destroy(gameObject);
    }
}