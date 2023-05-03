using System;
using UnityEngine;
using UnityEngine.EventSystems;

public class SwitchButton : MonoBehaviour, IPointerDownHandler, IPointerClickHandler,
    IPointerUpHandler
{
    public SwitchMode switchMode;
    public AnimationCurve onPressCurve;

    private static AudioClip _mouseDownAudioClip;
    private static AudioClip _mouseUpAudioClip;
    private AudioSource _audioSource;
    private bool _onDownAnimation, _onUpAnimation;
    private float _timeStart;
    private float _shopBaseInitialLocalPosY;

    private void Start()
    {
        _mouseDownAudioClip = Resources.Load("Raws/click_down_003") as AudioClip;
        _mouseUpAudioClip = Resources.Load("Raws/click_up_002") as AudioClip;
        _audioSource = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>()
            .GetComponent<AudioSource>();
        _shopBaseInitialLocalPosY = transform.localPosition.y;
    }

    private void Update()
    {
        if (!_onDownAnimation && !_onUpAnimation)
            return;

        var t = Time.time - _timeStart;
        float localY = default;
        if (_onDownAnimation)
            localY = -15f * onPressCurve.Evaluate(t * 1 / 0.06f);
        else if (_onUpAnimation)
            localY = -15f + 15f * onPressCurve.Evaluate(t * 1 / 0.06f);

        transform.localPosition = new Vector2(0, _shopBaseInitialLocalPosY + localY);
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        switchMode.Switch();
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        _audioSource.PlayOneShot(_mouseDownAudioClip);
        _timeStart = Time.time;
        _onDownAnimation = true;
        _onUpAnimation = false;
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        _audioSource.PlayOneShot(_mouseUpAudioClip);
        _timeStart = Time.time;
        _onDownAnimation = false;
        _onUpAnimation = true;
    }
}