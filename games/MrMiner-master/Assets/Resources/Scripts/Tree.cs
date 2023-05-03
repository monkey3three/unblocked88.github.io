using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using utiles;
using Random = UnityEngine.Random;

public class Tree : MonoBehaviour
{
    public GameObject leaf;
    public GameObject dropLog;
    public GameObject praiseText;
    public AnimationCurve clickSpeedToLeafSpeed, clickSpeedToFloatingSpeed;
    public float dropChance = .5f;
    public float clickCurrentSpeed;
    public SpriteRenderer treeSpriteRenderer;

    private Animator _anim;
    private readonly ArrayList _clicks = new();
    private long _lastClick;
    private AudioClip[] _rustleAudioClip;
    private AudioClip[] _dropLogAudioClip;
    private static readonly int Down = Animator.StringToHash("Down");
    private static readonly int Up = Animator.StringToHash("Up");
    private static readonly int Bounce1Start = Animator.StringToHash("Bounce1Start");
    private static readonly int Bounce2Start = Animator.StringToHash("Bounce2Start");
    private static readonly int Speed = Animator.StringToHash("speed");
    private Camera _camera;
    public DataStorage dataStorage;
    private static readonly int Bounce = Animator.StringToHash("Bounce");
    private Animator _headerLogValueAnimator;
    private float _lastPraiseTime;

    private void Start()
    {
        _rustleAudioClip = new[]
        {
            Resources.Load("Raws/rustle_00") as AudioClip,
            Resources.Load("Raws/rustle_01") as AudioClip,
            Resources.Load("Raws/rustle_02") as AudioClip,
            Resources.Load("Raws/rustle_03") as AudioClip,
            Resources.Load("Raws/rustle_04") as AudioClip,
            Resources.Load("Raws/rustle_05") as AudioClip,
            Resources.Load("Raws/rustle_06") as AudioClip
        };
        _dropLogAudioClip = new[]
        {
            Resources.Load("Raws/drop_wood_00") as AudioClip,
            Resources.Load("Raws/drop_wood_01") as AudioClip,
            Resources.Load("Raws/drop_wood_02") as AudioClip,
            Resources.Load("Raws/drop_wood_03") as AudioClip,
            Resources.Load("Raws/drop_wood_04") as AudioClip,
            Resources.Load("Raws/drop_wood_05") as AudioClip
        };
        _anim = GetComponent<Animator>();
        _camera = Camera.main;
        _headerLogValueAnimator = GameObject.Find("Header_log_value").GetComponent<Animator>();
    }

    private void OnMouseDown()
    {
        if (DateTimeOffset.Now.ToUnixTimeMilliseconds() - _lastClick > 1000)
            _anim.SetTrigger(Down);
    }

    private void OnMouseExit()
    {
        _anim.SetTrigger(Up);
    }

    private void OnMouseUpAsButton()
    {
        if (_clicks.Count > 1 && (long) _clicks[^1] - (long) _clicks[0] > 1000)
            _clicks.RemoveRange(0, _clicks.Count - 2);

        _lastClick = DateTimeOffset.Now.ToUnixTimeMilliseconds();
        _clicks.Add(_lastClick);

        if (_clicks.Count > 1)
        {
            clickCurrentSpeed = (long) _clicks[^1] - (long) _clicks[^2];
            _anim.SetTrigger(clickCurrentSpeed > 200 ? Bounce1Start : Bounce2Start);
            _anim.SetFloat(Speed, (float) Math.Max(0.6, (330 - clickCurrentSpeed) / 250f * 1.9f));
        }
        else
        {
            clickCurrentSpeed = 1000;
            _anim.SetTrigger(Bounce1Start);
            _anim.SetFloat(Speed, 0.6f);
        }

        //Leafs drop
        var leafDropSpeed = _clicks.Count > 1 ? clickSpeedToLeafSpeed.Evaluate(clickCurrentSpeed) : 0.3f;
        for (var i = -1; i < (int) (leafDropSpeed / 0.6f); i++)
            Instantiate(leaf).GetComponent<LeafDrop>().speed = leafDropSpeed;

        Effect.ClickEffect(_camera.ScreenToWorldPoint(Input.mousePosition), utilies.HexToColor("#76E573"));
        Effect.SpawnFloatingText(Input.mousePosition,
            dataStorage.user.ClickPowerLog,
            _clicks.Count > 1 ? clickSpeedToFloatingSpeed.Evaluate(clickCurrentSpeed) : 2f);

        if (Random.Range(0f, 1f) < dropChance)
        {
            PlaySound(_dropLogAudioClip);
            var log = Instantiate(dropLog);
            log.GetComponent<LogResources>().speed =
                _clicks.Count > 1 ? clickSpeedToLeafSpeed.Evaluate(clickCurrentSpeed) + 0.1f : 0.4f;
        }
        else
            PlaySound(_rustleAudioClip);

        dataStorage.user.EarnClickLog();
        _headerLogValueAnimator.SetTrigger(Bounce);

        if (clickCurrentSpeed < 120 && Time.time - _lastPraiseTime > 1)
            SpawnPraiseText();
    }

    private void PlaySound(IReadOnlyList<AudioClip> audioClips)
    {
        var audioSource = GetComponent<AudioSource>();
        audioSource.clip = audioClips[Random.Range(0, audioClips.Count)];
        audioSource.PlayOneShot(audioSource.clip);
    }

    private void SpawnPraiseText()
    {
        _lastPraiseTime = Time.time;
        var deltaX = Screen.width * 0.4f;
        var deltaY = Screen.height * 0.25f;
        var xPos = Random.Range(deltaX / 2f, deltaX);
        xPos = Random.Range(0f, 1f) < 0.5 ? xPos : -xPos;
        var yPos = Random.Range(0, deltaY);
        var rotation = -xPos / deltaX * 45f;

        var center = new Vector2(Screen.width / 2f, Input.mousePosition.y);
        var pos = center + new Vector2(xPos, yPos);

        Instantiate(praiseText, pos, Quaternion.Euler(0, 0, rotation),
            GameObject.Find("Canvas").transform);
    }

    public void RandomScale()
    {
        treeSpriteRenderer.material.SetFloat("_Scale", Random.Range(3f, 60f));
    }
}