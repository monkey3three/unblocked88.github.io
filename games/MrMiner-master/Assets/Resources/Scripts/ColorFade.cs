using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ColorFade : MonoBehaviour
{
    public float duration = 1f;
    public AnimationCurve curve = AnimationCurve.Linear(0, 0, 1, 1);

    private Color _color = Color.clear;
    private Color _initialColor;
    private Component _component;
    private float _startTime;
    private bool _animationDone = true;
    private Type _type;
    private bool _goBack;
    private Image _image;
    private TextMeshProUGUI _text;

    private void Start()
    {
        if (TryGetComponent(out Image image))
            _image = image;
        if (TryGetComponent(out TextMeshProUGUI text))
            _text = text;
    }

    private void Update()
    {
        if (_animationDone)
            return;

        var t = (Time.time - _startTime) / duration;
        var color = Color.Lerp(_initialColor, _color, curve.Evaluate(t));
        if (_type == typeof(Image))
            _image.color = color;
        else if (_type == typeof(TextMeshProUGUI))
            _text.color = color;
        if (t > 1)
            _animationDone = true;
    }

    public void FadeToColor(Color initialColor, Color color, Type type)
    {
        _color = color;
        _type = type;
        _initialColor = initialColor;
        _startTime = Time.time;
        _animationDone = false;
    }
}