# Using OpenAI during development

The typical way AI is used in development is pre-emptive using such tools as the warp terminal, cursor editor, and the several AI plug-in like CoPilot to other editors.

Even my own parameterized prompt CLI systems falls into this category.

## Method Missing Intercept

The original experiment was made public by Scott Werner

https://gist.github.com/swerner/4c2e6c6e02b21dabe7d741e7becb4cb0

His approach to tying into the method_missing workflow works out okay for the kind of bottom up design experience commonly part of the trial and error approach to software design.  In that you create a library then an application program.  You focus on the application program using what you think should be in the library.... and running into all those NoMethod exceptions where they are not there.

This got me to think about other ways durning development where an openAI incept might be inserted.

## External Prompt to Handle TODO comment labels

I discovered that for small file sizes, a prompt can be crafted that will replace the TODO comment with Ruby code that implements the requirement articulated in the TODO comment.

For example

```ruby
def sort(an_array)
	# TODO: implement a classic bubble sort algorithm to order the parameter.  When an entry is nil, ensure that it is sorted to the top.  Return the newly sorted array.
end
```

Sending this file as part of the context of my `todo` prompt will generate a new Ruby file that implements all the TODO requirements in the provided file.

This works pretty good.  I'm going to stop playing with the other ideas.


## Exception Intercept

I often use a custome exception `NotImplemented` in method which I leave for later development.  When I get to the point in my testing where the expection is being raised I then focus on that method's implementation.

What if I do something like this:

```ruby
def sort(an_array)
	sorted_array = an_array.dup

	NotImplemented.needs_to <<~EOS
		Implement a classic bubble sort algorithm to order the sorted_array object
		in ascending order.  Ensure that all nil values are sorted to the top.  Allow
		nil values to always be less than whatever other value they are being
		conoarted ti.
	EOS

	return sorted_array
end
```

In this case `NotImplemented` is not an exception *per se* but it is a custom class with a class method that provides the requirements for code to be inserted at this point.  The interceptor can give the user a choice to 1) raise an exception, 2) continue without modification 3) send the require to the AI, receive the response, extract the code, insert the code, reload the file with the new code, and continue.
