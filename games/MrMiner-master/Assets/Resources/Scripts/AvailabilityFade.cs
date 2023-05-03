using UnityEngine;
using UnityEngine.UI;

public class AvailabilityFade : MonoBehaviour
{
    public float duration = 1f;
    private Color _color = Color.clear;
    private Color _initialColor;
    private Image _imageComponent;
    private float _startTime;
    private bool _animationDone = true;

    private void Start()
    {
        _imageComponent = GetComponent<Image>();
    }

    private void Update()
    {
        if (_animationDone)
            return;

        var t = (Time.time - _startTime) / duration;
        _imageComponent.color = Color.Lerp(_initialColor, _color, t);
        if (t > 1)
            _animationDone = true;
    }

    public void FadeToColor(Color color)
    {
        _color = color;
        _initialColor = GetComponent<Image>().color;
        _startTime = Time.time;
        _animationDone = false;
    }
}