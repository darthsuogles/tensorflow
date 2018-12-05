import tensorflow as tf
import numpy as np

def test_simple_convnet():
    graph = tf.Graph()
    with tf.Session(graph=graph) as sess:
        image_tensor = tf.placeholder(tf.float32, shape=[None, 112, 112, 3], name="image_tensor")
        conv_features = tf.layers.conv2d(image_tensor, filters=64, kernel_size=3, data_format='channels_last')

        sess.run(tf.global_variables_initializer())
        outs = sess.run(conv_features, feed_dict={image_tensor: np.random.randn(32, 112, 112, 3)})

    print(outs.shape)

if __name__ == '__main__':
    test_simple_convnet()
