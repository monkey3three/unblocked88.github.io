using TMPro;
using UnityEngine;

public class FloatingText : MonoBehaviour
{
    public AnimationCurve animationX, animationY;
    public float duration;
    [Range(0, 200)] public float horizontalDelta = 40;

    private float _startTime;
    private Vector2 _startPose;
    private TextMeshProUGUI[] _texts;
    private Camera _camera;

    private void Start()
    {
        _camera = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>();
        _startPose = transform.position;
        _texts = transform.GetComponentsInChildren<TextMeshProUGUI>();
        
        _startTime = Time.time;
    }

    private void Update()
    {
        var t = (Time.time - _startTime) / duration;
        transform.position = new Vector2(
            _startPose.x + horizontalDelta * animationX.Evaluate(t),
            _startPose.y - (_camera.rect.height - _startPose.y) * (animationY.Evaluate(t))
        );
        foreach (var text in _texts)
        {
            var col = text.color;
            col.a = 1 - animationY.Evaluate(t);
            text.color = col;
        }

        if (t > 1)
            Destroy(gameObject);
    }
}