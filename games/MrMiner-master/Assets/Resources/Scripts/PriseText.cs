using System.Collections;
using TMPro;
using UnityEngine;

public class PriseText : MonoBehaviour
{
    private static readonly int Start1 = Animator.StringToHash("Start");
    public TextMeshProUGUI text;
    public Animator animator;

    private void Start()
    {
        text.text = Sentences.PraiseSentences[Random.Range(0, Sentences.PraiseSentences.Length)];
        animator.SetTrigger(Start1);
    }

    public void EndPraiseText()
    {
        Destroy(gameObject);
    }
}