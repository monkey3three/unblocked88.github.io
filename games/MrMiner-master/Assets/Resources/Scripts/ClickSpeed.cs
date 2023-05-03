using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using TMPro;
using UnityEngine;

public class ClickSpeed : MonoBehaviour
{
    public AnimationCurve timeToScale;
    public TextMeshProUGUI text;
    public Tree tree;
    public Animator animator;

    private float _time;
    private static readonly int Start = Animator.StringToHash("Start");

    private void Update()
    {
        _time += Time.deltaTime;
        var time = tree.clickCurrentSpeed > 0 ? tree.clickCurrentSpeed : 300f;
        time *= 0.1f / 1000f;
        if (_time < time)
            return;
        var scale = timeToScale.Evaluate(time / 0.1f);
        var normalized = tree.clickCurrentSpeed > 0 ? 1000f / tree.clickCurrentSpeed : 0;
        if (Math.Abs(text.fontSize - scale) > 0.4f)
            animator.SetTrigger(Start);
        text.text = normalized.ToString("n2") + " cps";
        text.fontSize = scale;
        _time -= time;
    }
}